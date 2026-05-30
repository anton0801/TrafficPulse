import Foundation
import Combine

@MainActor
final class TrafficPulseSteerer: ObservableObject {

    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }
    
    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false
    
    private let orchestrator: PulseOrchestrator
    private var cancellables = Set<AnyCancellable>()
    private var deadlineTask: Task<Void, Never>?
    
    private var uiLocked: Bool = false
    
    init() {
        self.orchestrator = Assembler.shared.locate(PulseOrchestrator.self)
        wireUp()
    }
    
    deinit {
        deadlineTask?.cancel()
    }
    
    private func wireUp() {
        orchestrator.outcomePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] outcome in
                self?.handleOutcome(outcome)
            }
            .store(in: &cancellables)
    }
    
    func ignite() {
        Task {
            await orchestrator.bootSystem()
            armDeadline()
        }
    }
    
    func ingestAttribution(_ data: [String: Any]) {
        orchestrator.acceptBlips(data)
    }
    
    func ingestDeeplinks(_ data: [String: Any]) {
        orchestrator.acceptLights(data)
    }
    
    private var observer: Any? = nil
    
    func acceptConsent() {
        Task {
            await orchestrator.userAcceptsConsent()
        }
        observer = NotificationCenter.default.addObserver(self, selector: #selector(hidePrompt), name: Notification.Name("PUSH_REQUEST_DIS"), object: nil)
    }
    
    @objc private func hidePrompt() {
        self.showPermissionPrompt = false
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    func skipConsent() {
        showPermissionPrompt = false
        orchestrator.userSkipsConsent()
    }
    
    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }
    
    private func handleOutcome(_ outcome: PulseOutcome) {
        guard !uiLocked else {
            return
        }
        
        switch outcome {
        case .standby:
            break
        case .askConsent:
            showPermissionPrompt = true
        case .openShowcase:
            navigateToWeb = true
        case .sidelined:
            navigateToMain = true
        }
    }
    
    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            
            guard let self = self else { return }
            
            let shouldFire = self.orchestrator.reportDeadline()
            if shouldFire {
                self.handleOutcome(.sidelined)
            }
        }
    }
}
