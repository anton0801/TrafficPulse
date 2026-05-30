import Foundation
import Combine
import AppsFlyerLib

@MainActor
final class PulseOrchestrator {
    
    private let fsm: SignalStateMachine
    private let hooks: HookRegistry
    
    private let caddy: SignalsCaddy
    private let pulse: PulseProbe
    private let beacon: BeaconProbe
    private let permit: PermitGrant
    
    private let outcomeSubject = PassthroughSubject<PulseOutcome, Never>()
    var outcomePublisher: AnyPublisher<PulseOutcome, Never> {
        outcomeSubject.eraseToAnyPublisher()
    }
    
    private(set) var sequenceCompleted: Bool = false
    
    private var permitCancellable: AnyCancellable?
    
    init(
        fsm: SignalStateMachine,
        hooks: HookRegistry,
        caddy: SignalsCaddy,
        pulse: PulseProbe,
        beacon: BeaconProbe,
        permit: PermitGrant
    ) {
        self.fsm = fsm
        self.hooks = hooks
        self.caddy = caddy
        self.pulse = pulse
        self.beacon = beacon
        self.permit = permit
    }
    
    func bootSystem() async {
        guard !sequenceCompleted else { return }
        
        feedEvent(.wakeRequested)
        
        let archive = caddy.retrieveArchive()
        let revivedBeacon = Beacon.revive(from: archive)
        
        feedEvent(.archiveLoaded(revivedBeacon))
    }
    
    func acceptBlips(_ dict: [String: Any]) {
        guard !sequenceCompleted else { return }
        
        let mapped = dict.mapValues { "\($0)" }
        feedEvent(.blipsHarvested(mapped))
        feedEvent(.pulseInitiated)
    }
    
    func acceptLights(_ dict: [String: Any]) {
        guard !sequenceCompleted else { return }
        
        let mapped = dict.mapValues { "\($0)" }
        feedEvent(.lightsHarvested(mapped))
    }
    
    func userAcceptsConsent() async {
        feedEvent(.consentSolicited)
    }
    
    func userSkipsConsent() {
        feedEvent(.consentDeferred)
    }
    
    func reportDeadline() -> Bool {
        guard !sequenceCompleted else {
            return false
        }
        sequenceCompleted = true
        feedEvent(.deadlineStruck)
        return true
    }
    
    private func feedEvent(_ event: PhaseEvent) {
        guard let effects = fsm.feed(event) else {
            return
        }
        
        hooks.notifyPhaseEntered(fsm.currentPhase)
        
        Task {
            for effect in effects {
                if sequenceCompleted {
                    if case .launchConsentDialog = effect {} else
                    if case .enablePushReceiver = effect {} else
                    if case .publishOutcome(.openShowcase) = effect {} else
                    if case .persistBeacon = effect {} else {
                        continue
                    }
                }
                await executeEffect(effect)
            }
        }
    }
    
    private func executeEffect(_ effect: PhaseEffect) async {
        switch effect {
        case .persistBeacon:
            caddy.storeArchive(fsm.beacon.entomb())
            
        case .stampStorageRoute(let url, let mode):
            caddy.recordRoute(url: url, mode: mode)
            
        case .primeFlag:
            caddy.raisePrimedFlag()
            
        case .clearPushURL:
            UserDefaults.standard.removeObject(forKey: SignalsDictKey.pushURL)
            
        case .launchOrganicRefetch:
            await performOrganicRefetch()
            
        case .launchRoutingQuery:
            await performRoutingQuery()
            
        case .launchConsentDialog:
            await performConsentDialog()
            
        case .enablePushReceiver:
            permit.wirePushSensor()
            
        case .publishOutcome(let outcome):
            publishOutcome(outcome)
        }
    }
    
    // MARK: - Effect implementations
    
    private func performOrganicRefetch() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        guard !fsm.beacon.anchored else {
            feedEvent(.pulseInitiated)
            return
        }
        
        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        
        do {
            var fetched = try await pulse.tap(deviceID: deviceID)
            for (k, v) in fsm.beacon.lights {
                if fetched[k] == nil { fetched[k] = v }
            }
            let mapped = fetched.mapValues { "\($0)" }
            feedEvent(.organicResolved(mapped))
        } catch {
            feedEvent(.pulseInitiated)
        }
    }
    
    private func performRoutingQuery() async {
        feedEvent(.routingStarted)
        
        let seed = fsm.beacon.blips.mapValues { $0 as Any }
        
        do {
            let url = try await beacon.interrogate(seed: seed)
            feedEvent(.routeAnchored(url))
        } catch let hiccup as SignalHiccup {
            feedEvent(.routeBlocked(hiccup))
        } catch {
            feedEvent(.routeBlocked(SignalHiccup(.wireDown, stage: "orchestrator")))
        }
    }
    
    private func performConsentDialog() async {
        let priorState = (fsm.beacon.consentGreenlit, fsm.beacon.consentRedflagged)
        _ = priorState
        
        let future = permit.solicitPermit()
        
        permitCancellable = future.sink { [weak self] granted in
            guard let self = self else { return }
            self.feedEvent(.consentSettled(granted: granted))
            NotificationCenter.default.post(name: Notification.Name("PUSH_REQUEST_DIS"), object: nil)
        }
    }
    
    private func publishOutcome(_ outcome: PulseOutcome) {
        if case .standby = outcome {
            hooks.notifyOutcome(outcome)
            return
        }
        
        if !sequenceCompleted {
            sequenceCompleted = true
        }
        
        hooks.notifyOutcome(outcome)
        outcomeSubject.send(outcome)
    }
    
    func interceptPushURL(_ url: String) {
        feedEvent(.pushIntercepted(url))
    }
}
