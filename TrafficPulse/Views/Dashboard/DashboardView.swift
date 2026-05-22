import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var trafficVM: TrafficViewModel
    @EnvironmentObject var fuelVM: FuelViewModel
    @Binding var selectedTab: AppTab

    @State private var showAddTrip = false
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var appeared = false
    @State private var scoreGlow: Double = 0
    @State private var timeString = ""

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                GridPattern().ignoresSafeArea().opacity(0.6)
                ScanLineOverlay().ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {

                        // MARK: Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Circle().fill(Color.freeRoad).frame(width: 7, height: 7)
                                        .scaleEffect(appeared ? 1.2 : 0.8)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: appeared)
                                    Text("LIVE MONITOR")
                                        .font(AppFont.caption(10))
                                        .foregroundColor(.cctv.opacity(0.8))
                                        .tracking(2)
                                }
                                Text("Traffic Pulse")
                                    .font(AppFont.title(26))
                                    .foregroundColor(.textPrimary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(timeString)
                                    .font(AppFont.mono(16))
                                    .foregroundColor(.cctv)
                                Text(Date(), format: .dateTime.day().month().year())
                                    .font(AppFont.caption(11))
                                    .foregroundColor(.textMuted)
                            }

                            Button { showSettings = true } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.textSecondary)
                                    .padding(10)
                                    .background(Color.cardBg)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.leading, 8)
                        }
                        .padding(.horizontal, 18)
                        .offset(y: appeared ? 0 : -20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring.delay(0.1), value: appeared)

                        // MARK: Traffic Score Card
                        trafficScoreCard
                            .offset(y: appeared ? 0 : 30)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring.delay(0.15), value: appeared)

                        // MARK: Quick Stats Row
                        HStack(spacing: 12) {
                            quickStatCard(title: "Trips Today", value: "\(tripVM.todayTrips.count)", icon: "car.fill", color: .cctv)
                            quickStatCard(title: "Delay Today", value: "\(tripVM.totalDelayToday)m", icon: "clock.badge.exclamationmark", color: .activeFlow)
                            quickStatCard(title: "Avg Score", value: "\(tripVM.avgScoreToday)", icon: "chart.line.uptrend.xyaxis", color: .freeRoad)
                        }
                        .padding(.horizontal, 18)
                        .offset(y: appeared ? 0 : 30)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring.delay(0.2), value: appeared)

                        // MARK: Quick Actions
                        quickActionsSection

                        // MARK: Recent Trips
                        recentTripsSection

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                updateTime()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { appeared = true }
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scoreGlow = 1
                }
            }
            .onReceive(timer) { _ in updateTime() }
            .sheet(isPresented: $showAddTrip) { AddTripView() }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(isPresented: $showHistory) { HistoryView() }
        }
    }

    // MARK: Traffic Score Card
    var trafficScoreCard: some View {
        AppCard {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.cardBg, trafficVM.statusColor.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .cornerRadius(Radius.lg)

                HStack(spacing: 20) {
                    // Score Gauge
                    ZStack {
                        Circle()
                            .stroke(Color.textMuted.opacity(0.15), lineWidth: 8)
                            .frame(width: 90, height: 90)

                        Circle()
                            .trim(from: 0, to: CGFloat(trafficVM.currentScore) / 100.0)
                            .stroke(
                                AngularGradient(colors: [trafficVM.statusColor.opacity(0.3), trafficVM.statusColor],
                                                center: .center),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: trafficVM.statusColor.opacity(scoreGlow * 0.4), radius: 8)
                            .animation(.spring, value: trafficVM.currentScore)

                        VStack(spacing: 0) {
                            Text("\(trafficVM.currentScore)")
                                .font(AppFont.mono(22))
                                .foregroundColor(trafficVM.statusColor)
                            Text("SCORE")
                                .font(AppFont.caption(8))
                                .foregroundColor(.textMuted)
                                .tracking(2)
                        }
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            StatusBadge(text: trafficVM.currentStatus, color: trafficVM.statusColor)
                            if trafficVM.isRefreshing {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .tint(.cctv)
                            }
                        }

                        Text("Traffic conditions are updated in real time. Tap refresh to reload.")
                            .font(AppFont.body(12))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(2)

                        Button {
                            trafficVM.simulateRefresh()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .semibold))
                                    .rotationEffect(.degrees(trafficVM.isRefreshing ? 360 : 0))
                                    .animation(.linear(duration: 1).repeatWhile(trafficVM.isRefreshing), value: trafficVM.isRefreshing)
                                Text("Refresh")
                                    .font(AppFont.body(12))
                            }
                            .foregroundColor(.cctv)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.cctv.opacity(0.12))
                            .cornerRadius(Radius.pill)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(trafficVM.isRefreshing)
                    }

                    Spacer()
                }
                .padding(18)
            }
        }
        .padding(.horizontal, 18)
    }

    func quickStatCard(title: String, value: String, icon: String, color: Color) -> some View {
        AppCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)

                Text(value)
                    .font(AppFont.mono(20))
                    .foregroundColor(.textPrimary)

                Text(title)
                    .font(AppFont.caption(10))
                    .foregroundColor(.textMuted)
                    .tracking(1)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
    }

    // MARK: Quick Actions
    var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Quick Actions")

            HStack(spacing: 12) {
                quickActionButton(icon: "plus.circle.fill", label: "Add Trip", color: .cctv) {
                    showAddTrip = true
                }
                quickActionButton(icon: "map.fill", label: "Open Map", color: .freeRoad) {
                    selectedTab = .map
                }
                quickActionButton(icon: "chart.bar.fill", label: "Reports", color: .activeFlow) {
                    selectedTab = .reports
                }
                quickActionButton(icon: "clock.arrow.circlepath", label: "History", color: .warning) {
                    showHistory = true
                }
            }
        }
        .padding(.horizontal, 18)
        .offset(y: appeared ? 0 : 30)
        .opacity(appeared ? 1 : 0)
        .animation(.spring.delay(0.25), value: appeared)
    }

    func quickActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(color.opacity(0.15)).frame(width: 50, height: 50)
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(color)
                }
                Text(label)
                    .font(AppFont.caption(10))
                    .foregroundColor(.textSecondary)
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: Recent Trips
    var recentTripsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader("Today's Trips")
                Spacer()
                Button("See All") { selectedTab = .trips }
                    .font(AppFont.body(13))
                    .foregroundColor(.cctv)
            }
            .padding(.horizontal, 18)

            if tripVM.todayTrips.isEmpty {
                AppCard {
                    VStack(spacing: 12) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.textMuted.opacity(0.5))
                        Text("No trips today")
                            .font(AppFont.body(14))
                            .foregroundColor(.textMuted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(28)
                }
                .padding(.horizontal, 18)
            } else {
                ForEach(Array(tripVM.todayTrips.prefix(3).enumerated()), id: \.element.id) { idx, trip in
                    TripRowCard(trip: trip)
                        .padding(.horizontal, 18)
                        .offset(y: appeared ? 0 : 20)
                        .opacity(appeared ? 1 : 0)
                        .animation(.spring.delay(0.3 + Double(idx) * 0.07), value: appeared)
                }
            }
        }
    }

    func sectionHeader(_ text: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.cctv)
                .frame(width: 3, height: 16)
                .cornerRadius(2)
            Text(text)
                .font(AppFont.headline(16))
                .foregroundColor(.textPrimary)
        }
    }

    private func updateTime() {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        timeString = f.string(from: Date())
    }
}

// MARK: - Trip Row Card
struct TripRowCard: View {
    let trip: Trip
    @State private var pressed = false

    var body: some View {
        AppCard {
            HStack(spacing: 14) {
                // Status icon
                ZStack {
                    Circle()
                        .fill(trip.status.color.opacity(0.15))
                        .frame(width: 42, height: 42)
                    Image(systemName: trip.status.icon)
                        .font(.system(size: 18))
                        .foregroundColor(trip.status.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.name)
                        .font(AppFont.headline(14))
                        .foregroundColor(.textPrimary)
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.textMuted)
                        Text("\(trip.origin) → \(trip.destination)")
                            .font(AppFont.body(12))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(text: trip.status.rawValue, color: trip.status.color)
                    if trip.delayMinutes > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "clock.badge.exclamationmark")
                                .font(.system(size: 9))
                                .foregroundColor(.activeFlow)
                            Text("+\(trip.delayMinutes)m")
                                .font(AppFont.mono(11))
                                .foregroundColor(.activeFlow)
                        }
                    }
                    Text(trip.date, format: .dateTime.hour().minute())
                        .font(AppFont.caption(10))
                        .foregroundColor(.textMuted)
                }
            }
            .padding(14)
        }
        .scaleEffect(pressed ? 0.97 : 1.0)
        .animation(.springFast, value: pressed)
    }
}

// MARK: - Animation helper
extension Animation {
    func repeatWhile(_ condition: Bool) -> Animation {
        condition ? self.repeatForever(autoreverses: false) : self
    }
}
