import SwiftUI

@main
struct TrafficPulseApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var tripVM = TripViewModel()
    @StateObject private var routeVM = RouteViewModel()
    @StateObject private var fuelVM = FuelViewModel()
    @StateObject private var trafficVM = TrafficViewModel()
    @StateObject private var notifVM = NotificationViewModel()
    @StateObject private var recsVM = RecommendationsViewModel()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashView(isActive: $showSplash)
                        .transition(.identity)
                } else if !hasCompletedOnboarding {
                    OnboardingView()
                        .environmentObject(appState)
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .environmentObject(appState)
                        .environmentObject(tripVM)
                        .environmentObject(routeVM)
                        .environmentObject(fuelVM)
                        .environmentObject(trafficVM)
                        .environmentObject(notifVM)
                        .environmentObject(recsVM)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: showSplash)
            .animation(.easeInOut(duration: 0.4), value: hasCompletedOnboarding)
            .preferredColorScheme(appState.preferredColorScheme)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OnboardingComplete"))) { _ in
                hasCompletedOnboarding = true
            }
        }
    }
}
