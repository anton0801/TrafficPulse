import Foundation

@MainActor
final class Assembler {
    
    static let shared = Assembler()
    
    private var registry: [String: Any] = [:]
    
    private init() {}
    
    func provide<T>(_ instance: T, for type: T.Type) {
        let key = String(describing: type)
        registry[key] = instance
    }
    
    // MARK: - Lookup
    
    func locate<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let instance = registry[key] as? T else {
            fatalError("Assembler: no service for \(key)")
        }
        return instance
    }
    
    func tryLocate<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return registry[key] as? T
    }
    
    func bootstrapProduction() {
        provide(PlistCaddy() as SignalsCaddy, for: SignalsCaddy.self)
        provide(AppsFlyerPulseProbe() as PulseProbe, for: PulseProbe.self)
        provide(HTTPBeaconProbe() as BeaconProbe, for: BeaconProbe.self)
        provide(NotificationPermitGrant() as PermitGrant, for: PermitGrant.self)
        
        let machine = SignalStateMachine()
        let hookReg = HookRegistry()
        hookReg.attach(ConsoleLoggerHook())
        
        provide(machine, for: SignalStateMachine.self)
        provide(hookReg, for: HookRegistry.self)
        
        let orchestrator = PulseOrchestrator(
            fsm: machine,
            hooks: hookReg,
            caddy: locate(SignalsCaddy.self),
            pulse: locate(PulseProbe.self),
            beacon: locate(BeaconProbe.self),
            permit: locate(PermitGrant.self)
        )
        provide(orchestrator, for: PulseOrchestrator.self)
    }
}
