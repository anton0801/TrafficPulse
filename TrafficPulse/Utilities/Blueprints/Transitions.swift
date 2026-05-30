import Foundation

struct TransitionResult {
    let nextPhase: SignalPhase
    let beaconMutator: ((inout Beacon) -> Void)?
    let effects: [PhaseEffect]
}

@MainActor
enum TransitionTable {
    
    static func resolve(
        phase: SignalPhase,
        event: PhaseEvent,
        beacon: Beacon
    ) -> TransitionResult? {
        
        switch (phase, event) {
        
        case (.dormant, .wakeRequested):
            return TransitionResult(
                nextPhase: .dormant,
                beaconMutator: nil,
                effects: []
            )
            
        case (.dormant, .archiveLoaded(let revivedBeacon)):
            return TransitionResult(
                nextPhase: .revived,
                beaconMutator: { $0 = revivedBeacon },
                effects: []
            )
        
        case (.revived, .blipsHarvested(let dict)),
             (.ignited, .blipsHarvested(let dict)):
            return TransitionResult(
                nextPhase: phase,
                beaconMutator: { $0.blips = dict },
                effects: [.persistBeacon]
            )
            
        case (.revived, .lightsHarvested(let dict)),
             (.ignited, .lightsHarvested(let dict)),
             (.routing, .lightsHarvested(let dict)):
            return TransitionResult(
                nextPhase: phase,
                beaconMutator: { $0.lights = dict },
                effects: [.persistBeacon]
            )
            
        case (.anchored, .blipsHarvested), (.stalled, .blipsHarvested), (.terminus, .blipsHarvested):
            return nil
        case (.anchored, .lightsHarvested), (.stalled, .lightsHarvested), (.terminus, .lightsHarvested):
            return nil
        
        case (.revived, .pulseInitiated):
            if let pushURL = UserDefaults.standard.string(forKey: SignalsDictKey.pushURL),
               !pushURL.isEmpty {
                let needsConsent = beacon.consentRipe
                return TransitionResult(
                    nextPhase: .anchored,
                    beaconMutator: { snap in
                        snap.routeURL = pushURL
                        snap.routeMode = "Active"
                        snap.unscanned = false
                        snap.anchored = true
                    },
                    effects: [
                        .persistBeacon,
                        .stampStorageRoute(url: pushURL, mode: "Active"),
                        .primeFlag,
                        .clearPushURL,
                        .publishOutcome(needsConsent ? .askConsent : .openShowcase)
                    ]
                )
            }
            
            guard beacon.blipsReady else {
                return TransitionResult(
                    nextPhase: .ignited,
                    beaconMutator: nil,
                    effects: [.publishOutcome(.standby)]
                )
            }
            
            if beacon.organicLane && beacon.unscanned && !beacon.organicCovered {
                return TransitionResult(
                    nextPhase: .ignited,
                    beaconMutator: { $0.organicCovered = true },
                    effects: [.persistBeacon, .launchOrganicRefetch]
                )
            }
            
            return TransitionResult(
                nextPhase: .routing,
                beaconMutator: nil,
                effects: [.launchRoutingQuery]
            )
        
        case (.ignited, .pulseInitiated):
            if let pushURL = UserDefaults.standard.string(forKey: SignalsDictKey.pushURL),
               !pushURL.isEmpty {
                let needsConsent = beacon.consentRipe
                return TransitionResult(
                    nextPhase: .anchored,
                    beaconMutator: { snap in
                        snap.routeURL = pushURL
                        snap.routeMode = "Active"
                        snap.unscanned = false
                        snap.anchored = true
                    },
                    effects: [
                        .persistBeacon,
                        .stampStorageRoute(url: pushURL, mode: "Active"),
                        .primeFlag,
                        .clearPushURL,
                        .publishOutcome(needsConsent ? .askConsent : .openShowcase)
                    ]
                )
            }
            
            guard beacon.blipsReady else {
                return TransitionResult(nextPhase: .ignited, beaconMutator: nil, effects: [.publishOutcome(.standby)])
            }
            
            if beacon.organicLane && beacon.unscanned && !beacon.organicCovered {
                return TransitionResult(
                    nextPhase: .ignited,
                    beaconMutator: { $0.organicCovered = true },
                    effects: [.persistBeacon, .launchOrganicRefetch]
                )
            }
            
            return TransitionResult(
                nextPhase: .routing,
                beaconMutator: nil,
                effects: [.launchRoutingQuery]
            )
            
        case (.ignited, .organicResolved(let dict)):
            return TransitionResult(
                nextPhase: .routing,
                beaconMutator: { $0.blips = dict },
                effects: [.persistBeacon, .launchRoutingQuery]
            )
        
        case (.routing, .routeAnchored(let url)):
            let needsConsent = beacon.consentRipe
            return TransitionResult(
                nextPhase: .anchored,
                beaconMutator: { snap in
                    snap.routeURL = url
                    snap.routeMode = "Active"
                    snap.unscanned = false
                    snap.anchored = true
                },
                effects: [
                    .persistBeacon,
                    .stampStorageRoute(url: url, mode: "Active"),
                    .primeFlag,
                    .clearPushURL,
                    .publishOutcome(needsConsent ? .askConsent : .openShowcase)
                ]
            )
            
        case (.routing, .routeBlocked(_)):
            return TransitionResult(
                nextPhase: .stalled,
                beaconMutator: nil,
                effects: [.publishOutcome(.sidelined)]
            )
        
        case (.anchored, .consentSolicited):
            return TransitionResult(
                nextPhase: .anchored,
                beaconMutator: nil,
                effects: [.launchConsentDialog]
            )
            
        case (.anchored, .consentSettled(let granted)):
            let now = Date()
            return TransitionResult(
                nextPhase: .terminus,
                beaconMutator: { snap in
                    snap.consentGreenlit = granted
                    snap.consentRedflagged = !granted
                    snap.consentStampedAt = now
                },
                effects: [
                    .persistBeacon,
                    granted ? .enablePushReceiver : .publishOutcome(.openShowcase),
                    .publishOutcome(.openShowcase)
                ]
            )
            
        case (.anchored, .consentDeferred):
            let now = Date()
            return TransitionResult(
                nextPhase: .terminus,
                beaconMutator: { snap in
                    snap.consentStampedAt = now
                },
                effects: [.persistBeacon, .publishOutcome(.openShowcase)]
            )
        
        case (_, .pushIntercepted(let url)):
            guard phase != .terminus, phase != .stalled, phase != .anchored else {
                return nil
            }
            let needsConsent = beacon.consentRipe
            return TransitionResult(
                nextPhase: .anchored,
                beaconMutator: { snap in
                    snap.routeURL = url
                    snap.routeMode = "Active"
                    snap.unscanned = false
                    snap.anchored = true
                },
                effects: [
                    .persistBeacon,
                    .stampStorageRoute(url: url, mode: "Active"),
                    .primeFlag,
                    .clearPushURL,
                    .publishOutcome(needsConsent ? .askConsent : .openShowcase)
                ]
            )
        
        case (_, .deadlineStruck):
            guard phase != .terminus, phase != .stalled, phase != .anchored else {
                return nil
            }
            return TransitionResult(
                nextPhase: .stalled,
                beaconMutator: nil,
                effects: [.publishOutcome(.sidelined)]
            )
           
        default:
            return nil
        }
    }
}
