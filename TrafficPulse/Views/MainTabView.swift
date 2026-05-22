import SwiftUI

// MARK: - Main Tab Bar
enum AppTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case trips = "Trips"
    case map = "Map"
    case fuel = "Fuel"
    case reports = "Reports"

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .trips: return "car.fill"
        case .map: return "map.fill"
        case .fuel: return "fuelpump.fill"
        case .reports: return "chart.bar.fill"
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var tripVM = TripViewModel()
    @StateObject var routeVM = RouteViewModel()
    @StateObject var fuelVM = FuelViewModel()
    @StateObject var trafficVM = TrafficViewModel()
    @StateObject var notifVM = NotificationViewModel()
    @StateObject var recsVM = RecommendationsViewModel()

    @State private var selectedTab: AppTab = .dashboard
    @State private var tabBarVisible = true

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView(selectedTab: $selectedTab)
                case .trips:
                    TripsView()
                case .map:
                    TrafficMapView()
                case .fuel:
                    FuelView()
                case .reports:
                    ReportsView()
                }
            }
            .environmentObject(tripVM)
            .environmentObject(routeVM)
            .environmentObject(fuelVM)
            .environmentObject(trafficVM)
            .environmentObject(notifVM)
            .environmentObject(recsVM)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Tab Bar
            CustomTabBar(selected: $selectedTab)
        }
        .background(Color.roadDark.ignoresSafeArea())
        .preferredColorScheme(appState.preferredColorScheme)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selected: AppTab
    @State private var bounceTab: AppTab? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarItem(tab: tab, selected: $selected, bounce: $bounceTab)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.cctv.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

struct TabBarItem: View {
    let tab: AppTab
    @Binding var selected: AppTab
    @Binding var bounce: AppTab?

    var isSelected: Bool { selected == tab }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                selected = tab
                bounce = tab
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { bounce = nil }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .cctv : .textMuted)
                    .scaleEffect(bounce == tab ? 1.25 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: bounce)

                if isSelected {
                    Capsule()
                        .fill(Color.cctv)
                        .frame(width: 20, height: 3)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(width: 20, height: 3)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
