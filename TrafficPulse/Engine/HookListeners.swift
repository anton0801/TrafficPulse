import Foundation

protocol HookListener: AnyObject {
    var listenerID: String { get }
    func onPhaseEntered(_ phase: SignalPhase)
    func onOutcomePublished(_ outcome: PulseOutcome)
}

@MainActor
final class HookRegistry {
    private var hooks: [HookListener] = []
    
    func attach(_ hook: HookListener) {
        hooks.append(hook)
    }
    
    func notifyPhaseEntered(_ phase: SignalPhase) {
        for hook in hooks {
            hook.onPhaseEntered(phase)
        }
    }
    
    func notifyOutcome(_ outcome: PulseOutcome) {
        for hook in hooks {
            hook.onOutcomePublished(outcome)
        }
    }
}

final class ConsoleLoggerHook: HookListener {
    let listenerID = "console.logger"
    
    func onPhaseEntered(_ phase: SignalPhase) {
    }
    
    func onOutcomePublished(_ outcome: PulseOutcome) {
    }
}
