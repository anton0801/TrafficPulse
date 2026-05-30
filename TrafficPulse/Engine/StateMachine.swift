import Foundation

@MainActor
final class SignalStateMachine {
    
    private(set) var currentPhase: SignalPhase = .dormant
    private(set) var beacon: Beacon = Beacon()
 
    func feed(_ event: PhaseEvent) -> [PhaseEffect]? {
        guard let transition = TransitionTable.resolve(
            phase: currentPhase,
            event: event,
            beacon: beacon
        ) else {
            return nil
        }
        
        let prevPhase = currentPhase
        
        // Apply mutator
        if let mutator = transition.beaconMutator {
            mutator(&beacon)
        }
        
        // Advance phase
        currentPhase = transition.nextPhase
        
//        if prevPhase != currentPhase {
//            print("\(SignalsVocabulary.logBeak) FSM: \(prevPhase.rawValue) → \(currentPhase.rawValue) via \(eventLabel(event))")
//        }
        
        return transition.effects
    }
    
    func describeState() -> String {
        "phase=\(currentPhase.rawValue) blips=\(beacon.blips.count) anchored=\(beacon.anchored)"
    }
    
    private func eventLabel(_ event: PhaseEvent) -> String {
        switch event {
        case .wakeRequested: return "wakeRequested"
        case .archiveLoaded: return "archiveLoaded"
        case .blipsHarvested: return "blipsHarvested"
        case .lightsHarvested: return "lightsHarvested"
        case .pulseInitiated: return "pulseInitiated"
        case .pushIntercepted: return "pushIntercepted"
        case .organicTouched: return "organicTouched"
        case .organicResolved: return "organicResolved"
        case .routingStarted: return "routingStarted"
        case .routeAnchored: return "routeAnchored"
        case .routeBlocked: return "routeBlocked"
        case .consentSolicited: return "consentSolicited"
        case .consentSettled: return "consentSettled"
        case .consentDeferred: return "consentDeferred"
        case .deadlineStruck: return "deadlineStruck"
        }
    }
}
