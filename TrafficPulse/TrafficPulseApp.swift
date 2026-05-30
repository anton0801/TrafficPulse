import SwiftUI

@main
struct TrafficPulseApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
    }
}

struct MainView: View {
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var appState = AppState()
    @StateObject private var tripVM = TripViewModel()
    @StateObject private var routeVM = RouteViewModel()
    @StateObject private var fuelVM = FuelViewModel()
    @StateObject private var trafficVM = TrafficViewModel()
    @StateObject private var notifVM = NotificationViewModel()
    @StateObject private var recsVM = RecommendationsViewModel()
    
    var body: some View {
        ZStack {
            if !hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .environmentObject(appState)
        .environmentObject(tripVM)
        .environmentObject(routeVM)
        .environmentObject(fuelVM)
        .environmentObject(trafficVM)
        .environmentObject(notifVM)
        .environmentObject(recsVM)
        .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
        .preferredColorScheme(appState.preferredColorScheme)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingComplete"))) { _ in
            hasCompletedOnboarding = true
        }
    }
    
}
