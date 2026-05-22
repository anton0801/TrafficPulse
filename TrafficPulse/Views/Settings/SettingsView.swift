import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var notifVM: NotificationViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showNotifications = false
    @State private var showTheme = false
    @State private var exportConfirm = false
    @State private var clearDataConfirm = false
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                GridPattern().ignoresSafeArea().opacity(0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {

                        // Theme
                        settingsSection("APPEARANCE") {
                            // Color theme
                            VStack(spacing: 0) {
                                settingsLabel("Color Theme")
                                HStack(spacing: 8) {
                                    ForEach(["dark", "light", "system"], id: \.self) { theme in
                                        Button {
                                            withAnimation(.spring) { appState.colorTheme = theme }
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: themeIcon(theme))
                                                    .font(.system(size: 12))
                                                Text(theme.capitalized)
                                                    .font(AppFont.body(13))
                                            }
                                            .foregroundColor(appState.colorTheme == theme ? .nightBg : .textSecondary)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(appState.colorTheme == theme ? Color.cctv : Color.nightBg)
                                            .cornerRadius(Radius.pill)
                                            .overlay(Capsule().stroke(Color.cctv.opacity(appState.colorTheme == theme ? 0 : 0.2), lineWidth: 1))
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 16).padding(.bottom, 16)

                                Divider().background(Color.cctv.opacity(0.1)).padding(.horizontal, 16)

                                // Animation speed
                                VStack(spacing: 6) {
                                    settingsLabel("Animation Speed")
                                    HStack {
                                        Image(systemName: "tortoise.fill").foregroundColor(.textMuted).font(.system(size: 12))
                                        Slider(value: $appState.animationSpeed, in: 0.3...2.0, step: 0.1).tint(.cctv)
                                        Image(systemName: "hare.fill").foregroundColor(.textMuted).font(.system(size: 12))
                                        Text(String(format: "×%.1f", appState.animationSpeed))
                                            .font(AppFont.mono(12)).foregroundColor(.cctv).frame(width: 32)
                                    }
                                    .padding(.horizontal, 16).padding(.bottom, 16)
                                }
                            }
                        }

                        // Units
                        settingsSection("UNITS") {
                            VStack(spacing: 0) {
                                settingsPicker("Distance", selection: $appState.distanceUnit, options: ["km", "mi"])
                                Divider().background(Color.cctv.opacity(0.1)).padding(.horizontal, 16)
                                settingsPicker("Fuel", selection: $appState.fuelUnit, options: ["L", "gal"])
                                Divider().background(Color.cctv.opacity(0.1)).padding(.horizontal, 16)
                                settingsPicker("Language", selection: $appState.language, options: ["English", "Español", "Deutsch", "Français"])
                            }
                        }

                        // Notifications
                        settingsSection("NOTIFICATIONS") {
                            VStack(spacing: 0) {
                                Toggle(isOn: $notifVM.schedule.isEnabled) {
                                    settingsRowLabel("Enable Notifications", icon: "bell.fill", color: .cctv)
                                }
                                .tint(.cctv)
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                .onChange(of: notifVM.schedule.isEnabled) { _ in notifVM.saveAndSchedule() }

                                if notifVM.schedule.isEnabled {
                                    Divider().background(Color.cctv.opacity(0.1)).padding(.horizontal, 16)
                                    Toggle(isOn: $notifVM.schedule.morningAlert) {
                                        settingsRowLabel("Morning Traffic Alert", icon: "sunrise.fill", color: .warning)
                                    }
                                    .tint(.cctv).padding(.horizontal, 16).padding(.vertical, 12)
                                    .onChange(of: notifVM.schedule.morningAlert) { _ in notifVM.saveAndSchedule() }

                                    if notifVM.schedule.morningAlert {
                                        DatePicker("Alert Time", selection: $notifVM.schedule.morningTime, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.compact).colorScheme(.dark)
                                            .font(AppFont.body(14)).foregroundColor(.textSecondary).tint(.cctv)
                                            .padding(.horizontal, 16).padding(.bottom, 10)
                                            .onChange(of: notifVM.schedule.morningTime) { _ in notifVM.saveAndSchedule() }
                                    }

                                    Divider().background(Color.cctv.opacity(0.1)).padding(.horizontal, 16)
                                    Toggle(isOn: $notifVM.schedule.eveningAlert) {
                                        settingsRowLabel("Evening Rush Alert", icon: "sunset.fill", color: .activeFlow)
                                    }
                                    .tint(.cctv).padding(.horizontal, 16).padding(.vertical, 12)
                                    .onChange(of: notifVM.schedule.eveningAlert) { _ in notifVM.saveAndSchedule() }

                                    if notifVM.schedule.eveningAlert {
                                        DatePicker("Alert Time", selection: $notifVM.schedule.eveningTime, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(.compact).colorScheme(.dark)
                                            .font(AppFont.body(14)).foregroundColor(.textSecondary).tint(.cctv)
                                            .padding(.horizontal, 16).padding(.bottom, 10)
                                            .onChange(of: notifVM.schedule.eveningTime) { _ in notifVM.saveAndSchedule() }
                                    }

                                    Divider().background(Color.cctv.opacity(0.1)).padding(.horizontal, 16)
                                    Toggle(isOn: $notifVM.schedule.weeklyReport) {
                                        settingsRowLabel("Weekly Report (Monday)", icon: "chart.bar.fill", color: .freeRoad)
                                    }
                                    .tint(.cctv).padding(.horizontal, 16).padding(.vertical, 12)
                                    .onChange(of: notifVM.schedule.weeklyReport) { _ in notifVM.saveAndSchedule() }
                                }
                            }
                            .animation(.spring, value: notifVM.schedule.isEnabled)
                        }

                        // Data
                        settingsSection("DATA & BACKUP") {
                            VStack(spacing: 0) {
                                settingsButton("Export Data", icon: "square.and.arrow.up", color: .cctv) {
                                    withAnimation { exportConfirm = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        withAnimation { exportConfirm = false }
                                    }
                                }

                                Divider().background(Color.cctv.opacity(0.1)).padding(.horizontal, 16)
                                settingsButton("Clear All Data", icon: "trash.fill", color: .congestion) {
                                    clearDataConfirm = true
                                }
                            }
                        }

                        // App info
                        settingsSection("APP INFO") {
                            VStack(spacing: 0) {
                                infoRow("Version", value: "1.0.0")
                                Divider().background(Color.cctv.opacity(0.1)).padding(.horizontal, 16)
                                infoRow("Build", value: "100")
                                Divider().background(Color.cctv.opacity(0.1)).padding(.horizontal, 16)
                                infoRow("Distance Unit", value: appState.distanceUnit)
                                Divider().background(Color.cctv.opacity(0.1)).padding(.horizontal, 16)
                                infoRow("Theme", value: appState.colorTheme.capitalized)
                            }
                        }

                        Spacer().frame(height: 60)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }.foregroundColor(.cctv)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Clear All Data?", isPresented: $clearDataConfirm) {
                Button("Clear", role: .destructive) {
                    UserDefaults.standard.removeObject(forKey: "saved_trips")
                    UserDefaults.standard.removeObject(forKey: "saved_routes")
                    UserDefaults.standard.removeObject(forKey: "saved_fuel")
                    UserDefaults.standard.removeObject(forKey: "saved_traffic_events")
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All trips, routes, fuel, and events will be permanently deleted.")
            }
            .overlay(
                Group {
                    if exportConfirm {
                        SaveConfirmationBanner(message: "Data exported to Files!")
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }, alignment: .top
            )
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Helpers
    func settingsSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(AppFont.caption(11)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
                .padding(.horizontal, 18)

            AppCard { content() }
                .padding(.horizontal, 18)
        }
    }

    func settingsPicker(_ label: String, selection: Binding<String>, options: [String]) -> some View {
        HStack {
            Text(label).font(AppFont.body(15)).foregroundColor(.textPrimary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            }
            .pickerStyle(.menu)
            .tint(.cctv)
            .font(AppFont.body(15))
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    func settingsRowLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7).fill(color.opacity(0.15)).frame(width: 30, height: 30)
                Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
            }
            Text(title).font(AppFont.body(15)).foregroundColor(.textPrimary)
        }
    }

    func settingsLabel(_ text: String) -> some View {
        Text(text)
            .font(AppFont.body(14)).foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 10)
    }

    func settingsButton(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7).fill(color.opacity(0.15)).frame(width: 30, height: 30)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(color)
                }
                Text(label).font(AppFont.body(15)).foregroundColor(color)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(.textMuted)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).font(AppFont.body(15)).foregroundColor(.textSecondary)
            Spacer()
            Text(value).font(AppFont.mono(14)).foregroundColor(.textMuted)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    func themeIcon(_ theme: String) -> String {
        switch theme {
        case "dark": return "moon.fill"
        case "light": return "sun.max.fill"
        default: return "circle.lefthalf.filled"
        }
    }
}
