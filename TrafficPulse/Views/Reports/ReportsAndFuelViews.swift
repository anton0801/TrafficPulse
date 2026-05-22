import SwiftUI

// MARK: - Fuel View
struct FuelView: View {
    @EnvironmentObject var fuelVM: FuelViewModel
    @State private var showAdd = false
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                GridPattern().ignoresSafeArea().opacity(0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Fuel Notes")
                                    .font(AppFont.title(26)).foregroundColor(.textPrimary)
                                Text("\(fuelVM.entries.count) entries recorded")
                                    .font(AppFont.body(13)).foregroundColor(.textMuted)
                            }
                            Spacer()
                            Button { showAdd = true } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.nightBg).frame(width: 40, height: 40)
                                    .background(Color.warning).clipShape(Circle())
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)

                        // Summary cards
                        HStack(spacing: 12) {
                            fuelStat("Total Cost", value: String(format: "€%.2f", fuelVM.totalCost), color: .warning)
                            fuelStat("Total Liters", value: String(format: "%.1fL", fuelVM.totalLiters), color: .cctv)
                            fuelStat("Avg Price", value: String(format: "€%.2f/L", fuelVM.avgPrice), color: .freeRoad)
                        }
                        .padding(.horizontal, 18)
                        .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                        .animation(.spring.delay(0.1), value: appeared)

                        // Chart
                        fuelCostChart
                            .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                            .animation(.spring.delay(0.15), value: appeared)

                        // Entries list
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("FILL-UPS").font(AppFont.caption(11)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
                                Spacer()
                            }
                            .padding(.horizontal, 18)

                            ForEach(Array(fuelVM.entries.enumerated()), id: \.element.id) { idx, entry in
                                FuelEntryCard(entry: entry) {
                                    withAnimation { fuelVM.delete(entry) }
                                }
                                .padding(.horizontal, 18)
                                .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                                .animation(.spring.delay(0.2 + Double(idx) * 0.06), value: appeared)
                            }
                        }

                        Spacer().frame(height: 100)
                    }
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { appeared = true }
                }
            }
            .sheet(isPresented: $showAdd) { AddFuelEntryView() }
        }
    }

    var fuelCostChart: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("FUEL COSTS (LAST 3 FILLS)")
                    .font(AppFont.caption(10)).foregroundColor(.cctv.opacity(0.7)).tracking(2)

                if fuelVM.entries.isEmpty {
                    Text("No fuel data yet").font(AppFont.body(14)).foregroundColor(.textMuted)
                        .frame(maxWidth: .infinity).padding(.vertical, 20)
                } else {
                    let maxCost = fuelVM.entries.prefix(3).map { $0.totalCost }.max() ?? 1
                    HStack(alignment: .bottom, spacing: 16) {
                        ForEach(Array(fuelVM.entries.prefix(3).enumerated()), id: \.element.id) { idx, entry in
                            VStack(spacing: 6) {
                                Text(String(format: "€%.0f", entry.totalCost))
                                    .font(AppFont.mono(11)).foregroundColor(.warning)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(colors: [.warning, .warning.opacity(0.4)],
                                                         startPoint: .top, endPoint: .bottom))
                                    .frame(width: 32, height: appeared ? CGFloat(entry.totalCost / maxCost * 80) : 4)
                                    .animation(.spring.delay(Double(idx) * 0.1), value: appeared)
                                Text(entry.date, format: .dateTime.day().month().year())
                                    .font(AppFont.caption(9)).foregroundColor(.textMuted)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 18)
    }

    func fuelStat(_ label: String, value: String, color: Color) -> some View {
        AppCard {
            VStack(spacing: 6) {
                Text(value).font(AppFont.mono(15)).foregroundColor(color)
                Text(label).font(AppFont.caption(10)).foregroundColor(.textMuted).tracking(1).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 14)
        }
    }
}

// MARK: - Fuel Entry Card
struct FuelEntryCard: View {
    let entry: FuelEntry
    let onDelete: () -> Void
    @State private var showDeleteConfirm = false

    var body: some View {
        AppCard {
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.station.isEmpty ? "Station" : entry.station)
                            .font(AppFont.headline(14)).foregroundColor(.textPrimary)
                        Text(entry.date, format: .dateTime.day().month().year())
                            .font(AppFont.caption(12)).foregroundColor(.textMuted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "€%.2f", entry.totalCost))
                            .font(AppFont.mono(18)).foregroundColor(.warning)
                        Text(String(format: "%.1f L", entry.liters))
                            .font(AppFont.caption(11)).foregroundColor(.textMuted)
                    }
                }

                Divider().background(Color.cctv.opacity(0.1))

                HStack(spacing: 16) {
                    fuelDetail("Price/L", String(format: "€%.2f", entry.pricePerLiter))
                    fuelDetail("Odometer", String(format: "%.0f km", entry.odometer))
                    if !entry.notes.isEmpty {
                        fuelDetail("Note", entry.notes).lineLimit(1)
                    }
                    Spacer()
                    Button { showDeleteConfirm = true } label: {
                        Image(systemName: "trash").font(.system(size: 13)).foregroundColor(.congestion.opacity(0.7))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .alert("Delete this entry?", isPresented: $showDeleteConfirm) {
                        Button("Delete", role: .destructive) { onDelete() }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
            .padding(14)
        }
    }

    func fuelDetail(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(AppFont.caption(10)).foregroundColor(.textMuted).tracking(1)
            Text(value).font(AppFont.body(13)).foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Add Fuel Entry
struct AddFuelEntryView: View {
    @EnvironmentObject var fuelVM: FuelViewModel
    @Environment(\.dismiss) var dismiss

    @State private var liters = 40.0
    @State private var pricePerLiter = 1.65
    @State private var odometer = ""
    @State private var station = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var showConfirmation = false

    var totalCost: Double { liters * pricePerLiter }

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        // Live cost preview
                        AppCard {
                            VStack(spacing: 8) {
                                Text("TOTAL COST")
                                    .font(AppFont.caption(10)).foregroundColor(.textMuted).tracking(2)
                                Text(String(format: "€%.2f", totalCost))
                                    .font(.system(size: 42, weight: .bold, design: .monospaced))
                                    .foregroundStyle(LinearGradient(colors: [.warning, .activeFlow],
                                                                    startPoint: .leading, endPoint: .trailing))
                                    .animation(.spring, value: totalCost)
                            }
                            .frame(maxWidth: .infinity).padding(20)
                        }
                        .padding(.horizontal, 18)

                        formSection("Fuel Amount") {
                            VStack(spacing: 6) {
                                HStack {
                                    Text("Liters").font(AppFont.body(13)).foregroundColor(.textSecondary)
                                    Spacer()
                                    Text(String(format: "%.1f L", liters)).font(AppFont.mono(14)).foregroundColor(.cctv)
                                }
                                Slider(value: $liters, in: 1...80, step: 0.5).tint(.cctv)
                            }
                        }
                        formSection("Price per Liter") {
                            VStack(spacing: 6) {
                                HStack {
                                    Text("€/L").font(AppFont.body(13)).foregroundColor(.textSecondary)
                                    Spacer()
                                    Text(String(format: "€%.3f", pricePerLiter)).font(AppFont.mono(14)).foregroundColor(.warning)
                                }
                                Slider(value: $pricePerLiter, in: 0.8...3.0, step: 0.001).tint(.warning)
                            }
                        }
                        formSection("Station") {
                            styledField("Station name or location", text: $station)
                        }
                        formSection("Odometer") {
                            styledField("Current km reading", text: $odometer)
                                .keyboardType(.numberPad)
                        }
                        formSection("Date") {
                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .datePickerStyle(.compact).colorScheme(.dark).labelsHidden().tint(.cctv)
                        }
                        formSection("Notes") {
                            styledField("Optional notes", text: $notes)
                        }

                        VStack(spacing: 10) {
                            PrimaryButton("Save Entry", icon: "fuelpump.fill") { save() }
                            SecondaryButton("Cancel") { dismiss() }
                        }
                        .padding(.horizontal, 18).padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Add Fuel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .overlay(
            Group {
                if showConfirmation {
                    SaveConfirmationBanner(message: "Fuel entry saved!")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }, alignment: .top
        )
    }

    func save() {
        let odo = Double(odometer) ?? 0
        let entry = FuelEntry(date: date, liters: liters, pricePerLiter: pricePerLiter,
                               totalCost: totalCost, odometer: odo,
                               station: station.isEmpty ? "Unknown Station" : station, notes: notes)
        fuelVM.add(entry)
        withAnimation { showConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }

    func formSection<C: View>(_ label: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased()).font(AppFont.caption(11)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
            content()
        }.padding(.horizontal, 18)
    }

    func styledField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AppFont.body(15)).foregroundColor(.textPrimary).accentColor(.cctv)
            .padding(13).background(Color.nightBg).cornerRadius(Radius.md)
            .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.cctv.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Reports View
struct ReportsView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var fuelVM: FuelViewModel
    @EnvironmentObject var recsVM: RecommendationsViewModel
    @State private var appeared = false
    @State private var selectedPeriod = "Week"
    @State private var showRecs = false
    @State private var exportMessage = ""
    @State private var showExportConfirm = false

    let periods = ["Day", "Week", "Month"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                GridPattern().ignoresSafeArea().opacity(0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reports")
                                    .font(AppFont.title(26)).foregroundColor(.textPrimary)
                                Text("Your driving analytics")
                                    .font(AppFont.body(13)).foregroundColor(.textMuted)
                            }
                            Spacer()
                            periodPicker
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 16)
                        .offset(y: appeared ? 0 : -10).opacity(appeared ? 1 : 0)
                        .animation(.spring.delay(0.1), value: appeared)

                        // Summary
                        weeklySummaryCards
                            .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                            .animation(.spring.delay(0.15), value: appeared)

                        // Charts
                        trafficScoreChart
                            .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                            .animation(.spring.delay(0.2), value: appeared)

                        delayChart
                            .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                            .animation(.spring.delay(0.25), value: appeared)

                        // Fuel summary
                        fuelSummaryCard
                            .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                            .animation(.spring.delay(0.3), value: appeared)

                        // Action buttons
                        VStack(spacing: 10) {
                            PrimaryButton("View Recommendations", icon: "lightbulb.fill") {
                                showRecs = true
                            }
                            SecondaryButton("Export Report", icon: "square.and.arrow.up") {
                                withAnimation { exportMessage = "Report exported to Files app!" }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { exportMessage = "" }
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        Spacer().frame(height: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { appeared = true }
                }
            }
            .sheet(isPresented: $showRecs) { RecommendationsView() }
            .overlay(
                Group {
                    if !exportMessage.isEmpty {
                        SaveConfirmationBanner(message: exportMessage)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.top, 0)
                    }
                }, alignment: .top
            )
        }
    }

    var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(periods, id: \.self) { p in
                Button {
                    withAnimation(.spring) { selectedPeriod = p }
                } label: {
                    Text(p)
                        .font(AppFont.body(13))
                        .foregroundColor(selectedPeriod == p ? .nightBg : .textSecondary)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(selectedPeriod == p ? Color.cctv : Color.clear)
                        .cornerRadius(Radius.pill)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .background(Color.cardBg)
        .cornerRadius(Radius.pill)
        .overlay(Capsule().stroke(Color.cctv.opacity(0.2), lineWidth: 1))
    }

    var weeklySummaryCards: some View {
        let stats = tripVM.weeklyStats
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            summaryCard("Total Trips", value: "\(stats.totalTrips)", icon: "car.fill", color: .cctv)
            summaryCard("Total Distance", value: String(format: "%.0f km", stats.totalDistanceKm), icon: "road.lanes", color: .freeRoad)
            summaryCard("Total Delay", value: "\(stats.totalDelayMinutes)m", icon: "clock.badge.exclamationmark", color: .activeFlow)
            summaryCard("Avg Score", value: "\(stats.avgTrafficScore)", icon: "chart.line.uptrend.xyaxis", color: trafficColor(stats.avgTrafficScore))
        }
        .padding(.horizontal, 18)
    }

    func summaryCard(_ label: String, value: String, icon: String, color: Color) -> some View {
        AppCard {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
                VStack(alignment: .leading, spacing: 2) {
                    Text(value).font(AppFont.mono(17)).foregroundColor(.textPrimary)
                    Text(label).font(AppFont.caption(10)).foregroundColor(.textMuted).tracking(1)
                }
                Spacer()
            }
            .padding(14)
        }
    }

    var trafficScoreChart: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TRAFFIC SCORE").font(AppFont.caption(10)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
                        Text("7-Day Overview").font(AppFont.headline(14)).foregroundColor(.textPrimary)
                    }
                    Spacer()
                    Text("Avg: \(tripVM.weeklyStats.avgTrafficScore)")
                        .font(AppFont.mono(13)).foregroundColor(.cctv)
                }
                let data = tripVM.dailyScores()
                let maxVal = data.map { $0.1 }.max() ?? 100
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data, id: \.0) { day, score in
                        VStack(spacing: 4) {
                            if score > 0 {
                                Text("\(Int(score))").font(AppFont.caption(8)).foregroundColor(.textMuted)
                            }
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(colors: [trafficColor(Int(score)), trafficColor(Int(score)).opacity(0.3)],
                                                   startPoint: .top, endPoint: .bottom)
                                )
                                .frame(width: 28, height: appeared ? CGFloat((score / max(maxVal, 1)) * 80) + 4 : 4)
                                .animation(.spring.delay(0.05), value: appeared)
                            Text(day).font(AppFont.caption(10)).foregroundColor(.textMuted)
                        }
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 18)
    }

    var delayChart: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("DELAYS (MINUTES)").font(AppFont.caption(10)).foregroundColor(.activeFlow.opacity(0.8)).tracking(2)
                    Spacer()
                    Text("Total: \(tripVM.weeklyStats.totalDelayMinutes)m")
                        .font(AppFont.mono(12)).foregroundColor(.activeFlow)
                }
                let data = tripVM.delayByDay()
                let maxVal = data.map { $0.1 }.max() ?? 1
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(data, id: \.0) { day, delay in
                        VStack(spacing: 4) {
                            if delay > 0 {
                                Text("\(Int(delay))m").font(AppFont.caption(8)).foregroundColor(.activeFlow.opacity(0.8))
                            }
                            RoundedRectangle(cornerRadius: 3)
                                .fill(LinearGradient(colors: [.activeFlow, .activeFlow.opacity(0.3)],
                                                     startPoint: .top, endPoint: .bottom))
                                .frame(width: 28, height: appeared ? CGFloat((delay / max(maxVal, 1)) * 70) + 2 : 2)
                                .animation(.spring.delay(0.1), value: appeared)
                            Text(day).font(AppFont.caption(10)).foregroundColor(.textMuted)
                        }
                    }
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 18)
    }

    var fuelSummaryCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("FUEL SUMMARY").font(AppFont.caption(10)).foregroundColor(.warning.opacity(0.8)).tracking(2)
                HStack(spacing: 20) {
                    fuelItem("Total Cost", String(format: "€%.2f", fuelVM.totalCost))
                    fuelItem("Total Liters", String(format: "%.1f L", fuelVM.totalLiters))
                    fuelItem("Avg Price", String(format: "€%.2f/L", fuelVM.avgPrice))
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 18)
    }

    func fuelItem(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value).font(AppFont.mono(14)).foregroundColor(.warning)
            Text(label).font(AppFont.caption(10)).foregroundColor(.textMuted)
        }
    }
}

// MARK: - Recommendations View
struct RecommendationsView: View {
    @EnvironmentObject var recsVM: RecommendationsViewModel
    @Environment(\.dismiss) var dismiss
    @State private var appeared = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                GridPattern().ignoresSafeArea().opacity(0.5)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(Array(recsVM.recommendations.enumerated()), id: \.element.id) { idx, rec in
                            RecommendationCard(rec: rec, isAdded: recsVM.isAdded(rec.id)) {
                                recsVM.markAdded(rec.id)
                            }
                            .padding(.horizontal, 18)
                            .offset(y: appeared ? 0 : 20).opacity(appeared ? 1 : 0)
                            .animation(.spring.delay(Double(idx) * 0.07), value: appeared)
                        }
                        Spacer().frame(height: 40)
                    }
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Recommendations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(.cctv)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { appeared = true }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct RecommendationCard: View {
    let rec: Recommendation
    let isAdded: Bool
    let onAdd: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(rec.priority.color.opacity(0.15)).frame(width: 44, height: 44)
                        Image(systemName: rec.icon).font(.system(size: 18)).foregroundColor(rec.priority.color)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(rec.title).font(AppFont.headline(14)).foregroundColor(.textPrimary)
                            Spacer()
                            StatusBadge(text: rec.priority.rawValue, color: rec.priority.color)
                        }
                        Text(rec.category.uppercased())
                            .font(AppFont.caption(10)).foregroundColor(.textMuted).tracking(2)
                    }
                }
                Text(rec.description)
                    .font(AppFont.body(13)).foregroundColor(.textSecondary).lineSpacing(3)

                Button(action: onAdd) {
                    HStack(spacing: 6) {
                        Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle")
                            .font(.system(size: 14))
                        Text(isAdded ? "Added to Tasks" : "Add to Tasks")
                            .font(AppFont.body(13))
                    }
                    .foregroundColor(isAdded ? .freeRoad : .cctv)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(isAdded ? Color.freeRoad.opacity(0.12) : Color.cctv.opacity(0.12))
                    .cornerRadius(Radius.pill)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isAdded)
            }
            .padding(16)
        }
    }
}

// MARK: - History View
struct HistoryView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @EnvironmentObject var fuelVM: FuelViewModel
    @EnvironmentObject var trafficVM: TrafficViewModel
    @Environment(\.dismiss) var dismiss

    @State private var filterType = "All"
    @State private var appeared = false

    let types = ["All", "Trips", "Fuel", "Events"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                GridPattern().ignoresSafeArea().opacity(0.5)

                VStack(spacing: 0) {
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(types, id: \.self) { t in
                                FilterChip(label: t, isSelected: filterType == t) {
                                    withAnimation(.spring) { filterType = t }
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                    .padding(.vertical, 12)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            if filterType == "All" || filterType == "Trips" {
                                sectionHeader("Trips")
                                ForEach(tripVM.trips.prefix(10)) { trip in
                                    historyRow(icon: trip.status.icon, iconColor: trip.status.color,
                                               title: trip.name,
                                               subtitle: "\(trip.origin) → \(trip.destination)",
                                               detail: "\(trip.durationMinutes)min",
                                               date: trip.date)
                                }
                            }
                            if filterType == "All" || filterType == "Fuel" {
                                sectionHeader("Fuel")
                                ForEach(fuelVM.entries.prefix(5)) { entry in
                                    historyRow(icon: "fuelpump.fill", iconColor: .warning,
                                               title: entry.station,
                                               subtitle: String(format: "%.1f L", entry.liters),
                                               detail: String(format: "€%.2f", entry.totalCost),
                                               date: entry.date)
                                }
                            }
                            if filterType == "All" || filterType == "Events" {
                                sectionHeader("Traffic Events")
                                ForEach(trafficVM.events.prefix(5)) { event in
                                    historyRow(icon: event.type.icon, iconColor: event.type.color,
                                               title: event.type.rawValue,
                                               subtitle: event.location,
                                               detail: "\(event.durationMinutes)m",
                                               date: event.date)
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }.foregroundColor(.cctv)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { appeared = true }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    func sectionHeader(_ text: String) -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(Color.cctv).frame(width: 3, height: 14).cornerRadius(2)
            Text(text).font(AppFont.headline(14)).foregroundColor(.textPrimary)
            Spacer()
        }
        .padding(.top, 8)
    }

    func historyRow(icon: String, iconColor: Color, title: String, subtitle: String, detail: String, date: Date) -> some View {
        AppCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.15)).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 15)).foregroundColor(iconColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppFont.body(14)).foregroundColor(.textPrimary).lineLimit(1)
                    Text(subtitle).font(AppFont.caption(12)).foregroundColor(.textMuted).lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(detail).font(AppFont.mono(13)).foregroundColor(.cctv)
                    Text(date, format: .dateTime.day().month().year())
                        .font(AppFont.caption(10)).foregroundColor(.textMuted)
                }
            }
            .padding(12)
        }
    }
}
