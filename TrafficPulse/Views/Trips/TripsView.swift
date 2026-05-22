import SwiftUI

// MARK: - Trips Main View
struct TripsView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @State private var showAdd = false
    @State private var selectedTrip: Trip?
    @State private var appeared = false
    @State private var searchText = ""

    var displayedTrips: [Trip] {
        let base = tripVM.filteredTrips
        if searchText.isEmpty { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.origin.localizedCaseInsensitiveContains(searchText) ||
            $0.destination.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                GridPattern().ignoresSafeArea().opacity(0.5)

                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Trip Log")
                                .font(AppFont.title(26))
                                .foregroundColor(.textPrimary)
                            Text("\(tripVM.trips.count) total trips recorded")
                                .font(AppFont.body(13))
                                .foregroundColor(.textMuted)
                        }
                        Spacer()
                        Button { showAdd = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.nightBg)
                                .frame(width: 40, height: 40)
                                .background(Color.cctv)
                                .clipShape(Circle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    // Search
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textMuted)
                            .font(.system(size: 15))
                        TextField("Search trips...", text: $searchText)
                            .font(AppFont.body(15))
                            .foregroundColor(.textPrimary)
                            .accentColor(.cctv)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Color.cardBg)
                    .cornerRadius(Radius.md)
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.cctv.opacity(0.15), lineWidth: 1))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)

                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(label: "All", isSelected: tripVM.filterStatus == nil) {
                                tripVM.filterStatus = nil
                            }
                            ForEach(TripStatus.allCases, id: \.self) { s in
                                FilterChip(label: s.rawValue, isSelected: tripVM.filterStatus == s,
                                           color: s.color) {
                                    tripVM.filterStatus = tripVM.filterStatus == s ? nil : s
                                }
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                    .padding(.bottom, 12)

                    // List
                    if displayedTrips.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image(systemName: "car.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.textMuted.opacity(0.4))
                            Text("No trips found")
                                .font(AppFont.headline(16))
                                .foregroundColor(.textMuted)
                            Button("Add Your First Trip") { showAdd = true }
                                .font(AppFont.body(14))
                                .foregroundColor(.cctv)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                ForEach(Array(displayedTrips.enumerated()), id: \.element.id) { idx, trip in
                                    Button { selectedTrip = trip } label: {
                                        TripRowCard(trip: trip)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal, 18)
                                    .offset(y: appeared ? 0 : 20)
                                    .opacity(appeared ? 1 : 0)
                                    .animation(.spring.delay(Double(idx) * 0.05), value: appeared)
                                }
                            }
                            .padding(.bottom, 100)
                            .padding(.top, 4)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { appeared = true }
                }
            }
            .sheet(isPresented: $showAdd) { AddTripView() }
            .sheet(item: $selectedTrip) { trip in
                TripDetailView(trip: trip)
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = .cctv
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AppFont.body(13))
                .foregroundColor(isSelected ? .nightBg : .textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? color : Color.cardBg)
                .cornerRadius(Radius.pill)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? .clear : Color.textMuted.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .animation(.spring, value: isSelected)
    }
}

// MARK: - Add Trip View
struct AddTripView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var origin = ""
    @State private var destination = ""
    @State private var durationMinutes = 30
    @State private var delayMinutes = 0
    @State private var distanceKm = 10.0
    @State private var trafficScore = 70
    @State private var fuelUsed = 1.5
    @State private var notes = ""
    @State private var status: TripStatus = .completed
    @State private var date = Date()
    @State private var showConfirmation = false
    @State private var nameError = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Name
                        formSection("Trip Name") {
                            VStack(alignment: .leading, spacing: 4) {
                                styledTextField("e.g. Morning Commute", text: $name)
                                if nameError {
                                    Text("Name is required")
                                        .font(AppFont.caption(11))
                                        .foregroundColor(.congestion)
                                }
                            }
                        }

                        // Route
                        formSection("Route") {
                            VStack(spacing: 10) {
                                styledTextField("From (Origin)", text: $origin)
                                HStack(spacing: 8) {
                                    Rectangle().fill(Color.cctv.opacity(0.4)).frame(width: 2, height: 20)
                                    Image(systemName: "arrow.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(.cctv.opacity(0.6))
                                }
                                .padding(.leading, 14)
                                styledTextField("To (Destination)", text: $destination)
                            }
                        }

                        // Date & Status
                        formSection("Date & Status") {
                            VStack(spacing: 10) {
                                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(.compact)
                                    .colorScheme(.dark)
                                    .labelsHidden()
                                    .tint(.cctv)

                                HStack(spacing: 8) {
                                    ForEach(TripStatus.allCases, id: \.self) { s in
                                        Button {
                                            withAnimation(.spring) { status = s }
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: s.icon)
                                                    .font(.system(size: 11))
                                                Text(s.rawValue)
                                                    .font(AppFont.body(12))
                                            }
                                            .foregroundColor(status == s ? .nightBg : s.color)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 7)
                                            .background(status == s ? s.color : s.color.opacity(0.12))
                                            .cornerRadius(Radius.pill)
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                    }
                                }
                            }
                        }

                        // Trip Details
                        formSection("Trip Details") {
                            VStack(spacing: 14) {
                                sliderRow("Duration", value: $durationMinutes, range: 1...180, unit: "min", step: 1)
                                sliderRow("Delay", value: $delayMinutes, range: 0...120, unit: "min", step: 1)
                                sliderRow("Distance", value2: $distanceKm, range2: 0.5...200, unit: "km")
                                sliderRow("Traffic Score", value: $trafficScore, range: 0...100, unit: "", step: 1)
                                    .overlay(
                                        HStack {
                                            Spacer()
                                            StatusBadge(text: trafficScore > 70 ? "Clear" : trafficScore > 40 ? "Moderate" : "Heavy",
                                                        color: trafficColor(trafficScore))
                                        }
                                        .padding(.top, -24)
                                    )
                                sliderRow("Fuel Used", value2: $fuelUsed, range2: 0...50, unit: "L")
                            }
                        }

                        // Notes
                        formSection("Notes") {
                            TextEditor(text: $notes)
                                .font(AppFont.body(14))
                                .foregroundColor(.textPrimary)
                                .accentColor(.cctv)
                                .frame(minHeight: 80)
                                .padding(10)
                                .background(Color.nightBg)
                                .cornerRadius(Radius.md)
                                .overlay(RoundedRectangle(cornerRadius: Radius.md)
                                    .stroke(Color.cctv.opacity(0.2), lineWidth: 1))
                                .colorScheme(.dark)
                        }

                        // Buttons
                        VStack(spacing: 10) {
                            PrimaryButton("Save Trip", icon: "checkmark") { save() }
                            SecondaryButton("Cancel") { dismiss() }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Add Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .font(AppFont.headline(15))
                        .foregroundColor(.cctv)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(AppFont.body(15))
                        .foregroundColor(.textSecondary)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .overlay(
            Group {
                if showConfirmation {
                    SaveConfirmationBanner(message: "Trip saved!")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }, alignment: .top
        )
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            withAnimation { nameError = true }
            return
        }
        let trip = Trip(
            name: name.trimmingCharacters(in: .whitespaces),
            origin: origin.isEmpty ? "Unknown" : origin,
            destination: destination.isEmpty ? "Unknown" : destination,
            date: date,
            durationMinutes: durationMinutes,
            delayMinutes: delayMinutes,
            distanceKm: distanceKm,
            trafficScore: trafficScore,
            fuelUsed: fuelUsed,
            notes: notes,
            status: status,
            congestionSegments: []
        )
        tripVM.add(trip)
        withAnimation { showConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }

    func styledTextField(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(AppFont.body(15))
            .foregroundColor(.textPrimary)
            .accentColor(.cctv)
            .padding(13)
            .background(Color.nightBg)
            .cornerRadius(Radius.md)
            .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.cctv.opacity(0.2), lineWidth: 1))
    }

    func formSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(AppFont.caption(11))
                .foregroundColor(.cctv.opacity(0.7))
                .tracking(2)
            content()
        }
        .padding(.horizontal, 18)
    }

    func sliderRow(_ label: String, value: Binding<Int>, range: ClosedRange<Double>, unit: String, step: Double) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(AppFont.body(13))
                    .foregroundColor(.textSecondary)
                Spacer()
                Text("\(value.wrappedValue)\(unit.isEmpty ? "" : " \(unit)")")
                    .font(AppFont.mono(13))
                    .foregroundColor(.cctv)
            }
            Slider(value: Binding(get: { Double(value.wrappedValue) },
                                  set: { value.wrappedValue = Int($0) }),
                   in: range, step: step)
                .tint(.cctv)
        }
    }

    func sliderRow(_ label: String, value2: Binding<Double>, range2: ClosedRange<Double>, unit: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(AppFont.body(13))
                    .foregroundColor(.textSecondary)
                Spacer()
                Text(String(format: "%.1f %@", value2.wrappedValue, unit))
                    .font(AppFont.mono(13))
                    .foregroundColor(.cctv)
            }
            Slider(value: value2, in: range2)
                .tint(.cctv)
        }
    }
}

// MARK: - Trip Detail View
struct TripDetailView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @Environment(\.dismiss) var dismiss
    @State var trip: Trip
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                GridPattern().ignoresSafeArea().opacity(0.4)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header card
                        AppCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(trip.name)
                                            .font(AppFont.title(22))
                                            .foregroundColor(.textPrimary)
                                        Text(trip.date, format: .dateTime.weekday(.wide).day().month().hour().minute())
                                            .font(AppFont.body(13))
                                            .foregroundColor(.textMuted)
                                    }
                                    Spacer()
                                    StatusBadge(text: trip.status.rawValue, color: trip.status.color)
                                }

                                Divider().background(Color.cctv.opacity(0.15))

                                HStack(spacing: 6) {
                                    Image(systemName: "location.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.cctv)
                                    Text(trip.origin)
                                        .font(AppFont.body(14))
                                        .foregroundColor(.textPrimary)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted)
                                    Text(trip.destination)
                                        .font(AppFont.body(14))
                                        .foregroundColor(.textPrimary)
                                }
                            }
                            .padding(16)
                        }
                        .padding(.horizontal, 18)

                        // Stats grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            statCell("Duration", value: "\(trip.durationMinutes) min", icon: "clock.fill", color: .cctv)
                            statCell("Distance", value: String(format: "%.1f km", trip.distanceKm), icon: "road.lanes", color: .freeRoad)
                            statCell("Delay", value: "+\(trip.delayMinutes) min", icon: "clock.badge.exclamationmark", color: trip.delayCategory.color)
                            statCell("Traffic Score", value: "\(trip.trafficScore)/100", icon: "chart.line.uptrend.xyaxis", color: trafficColor(trip.trafficScore))
                            statCell("Fuel Used", value: String(format: "%.1f L", trip.fuelUsed), icon: "fuelpump.fill", color: .warning)
                            statCell("Status", value: trip.delayCategory.rawValue, icon: "flag.fill", color: trip.delayCategory.color)
                        }
                        .padding(.horizontal, 18)

                        // Congestion segments
                        if !trip.congestionSegments.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                sectionLabel("Congestion Points")
                                ForEach(trip.congestionSegments) { seg in
                                    AppCard {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(seg.name)
                                                    .font(AppFont.body(14))
                                                    .foregroundColor(.textPrimary)
                                                HStack(spacing: 4) {
                                                    ForEach(0..<3, id: \.self) { i in
                                                        Circle()
                                                            .fill(i < seg.severity ? Color.activeFlow : Color.textMuted.opacity(0.3))
                                                            .frame(width: 7, height: 7)
                                                    }
                                                    Text("Severity \(seg.severity)/3")
                                                        .font(AppFont.caption(11))
                                                        .foregroundColor(.textMuted)
                                                }
                                            }
                                            Spacer()
                                            Text("+\(seg.delayMinutes)m")
                                                .font(AppFont.mono(14))
                                                .foregroundColor(.activeFlow)
                                        }
                                        .padding(12)
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                        }

                        // Notes
                        if !trip.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                sectionLabel("Notes")
                                AppCard {
                                    Text(trip.notes)
                                        .font(AppFont.body(14))
                                        .foregroundColor(.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
                                }
                            }
                            .padding(.horizontal, 18)
                        }

                        // Actions
                        VStack(spacing: 10) {
                            PrimaryButton("Edit Trip", icon: "pencil") { showEdit = true }
                            HStack(spacing: 10) {
                                SecondaryButton("Duplicate", icon: "doc.on.doc") {
                                    tripVM.duplicate(trip)
                                    dismiss()
                                }
                                Button {
                                    withAnimation { showDeleteConfirm = true }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "trash").font(.system(size: 14))
                                        Text("Delete")
                                    }
                                    .font(AppFont.headline(14))
                                    .foregroundColor(.congestion)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.congestion.opacity(0.12))
                                    .cornerRadius(Radius.md)
                                    .overlay(RoundedRectangle(cornerRadius: Radius.md)
                                        .stroke(Color.congestion.opacity(0.3), lineWidth: 1))
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Trip Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.cctv)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Delete Trip?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    tripVM.delete(trip)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .sheet(isPresented: $showEdit) {
                EditTripView(trip: $trip)
            }
        }
        .preferredColorScheme(.dark)
    }

    func statCell(_ label: String, value: String, icon: String, color: Color) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Text(value)
                    .font(AppFont.mono(16))
                    .foregroundColor(.textPrimary)
                Text(label)
                    .font(AppFont.caption(10))
                    .foregroundColor(.textMuted)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }

    func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppFont.caption(11))
            .foregroundColor(.cctv.opacity(0.7))
            .tracking(2)
    }
}

// MARK: - Edit Trip View
struct EditTripView: View {
    @EnvironmentObject var tripVM: TripViewModel
    @Environment(\.dismiss) var dismiss
    @Binding var trip: Trip

    @State private var name: String
    @State private var origin: String
    @State private var destination: String
    @State private var durationMinutes: Int
    @State private var delayMinutes: Int
    @State private var distanceKm: Double
    @State private var trafficScore: Int
    @State private var fuelUsed: Double
    @State private var notes: String
    @State private var status: TripStatus
    @State private var showConfirmation = false

    init(trip: Binding<Trip>) {
        self._trip = trip
        let t = trip.wrappedValue
        _name = State(initialValue: t.name)
        _origin = State(initialValue: t.origin)
        _destination = State(initialValue: t.destination)
        _durationMinutes = State(initialValue: t.durationMinutes)
        _delayMinutes = State(initialValue: t.delayMinutes)
        _distanceKm = State(initialValue: t.distanceKm)
        _trafficScore = State(initialValue: t.trafficScore)
        _fuelUsed = State(initialValue: t.fuelUsed)
        _notes = State(initialValue: t.notes)
        _status = State(initialValue: t.status)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.roadDark.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        editField("Trip Name", text: $name)
                        editField("From", text: $origin)
                        editField("To", text: $destination)
                        editField("Notes", text: $notes, isMultiline: true)

                        sliderSection("Duration", value: $durationMinutes, range: 1...180, unit: "min")
                        sliderSection("Delay", value: $delayMinutes, range: 0...120, unit: "min")
                        sliderSectionD("Distance", value: $distanceKm, range: 0.5...200, unit: "km")
                        sliderSection("Traffic Score", value: $trafficScore, range: 0...100, unit: "")
                        sliderSectionD("Fuel Used", value: $fuelUsed, range: 0...50, unit: "L")

                        // Status picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("STATUS").font(AppFont.caption(11)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
                            HStack(spacing: 8) {
                                ForEach(TripStatus.allCases, id: \.self) { s in
                                    Button { withAnimation(.spring) { status = s } } label: {
                                        Text(s.rawValue)
                                            .font(AppFont.body(13))
                                            .foregroundColor(status == s ? .nightBg : s.color)
                                            .padding(.horizontal, 12).padding(.vertical, 8)
                                            .background(status == s ? s.color : s.color.opacity(0.12))
                                            .cornerRadius(Radius.pill)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 18)

                        VStack(spacing: 10) {
                            PrimaryButton("Save Changes", icon: "checkmark") { save() }
                            SecondaryButton("Cancel") { dismiss() }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 30)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .overlay(
            Group {
                if showConfirmation {
                    SaveConfirmationBanner(message: "Changes saved!")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }, alignment: .top
        )
    }

    private func save() {
        trip.name = name
        trip.origin = origin
        trip.destination = destination
        trip.durationMinutes = durationMinutes
        trip.delayMinutes = delayMinutes
        trip.distanceKm = distanceKm
        trip.trafficScore = trafficScore
        trip.fuelUsed = fuelUsed
        trip.notes = notes
        trip.status = status
        tripVM.update(trip)
        withAnimation { showConfirmation = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { dismiss() }
    }

    func editField(_ label: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased()).font(AppFont.caption(11)).foregroundColor(.cctv.opacity(0.7)).tracking(2)
            if isMultiline {
                TextEditor(text: text)
                    .font(AppFont.body(15)).foregroundColor(.textPrimary).accentColor(.cctv)
                    .frame(minHeight: 70).padding(10)
                    .background(Color.nightBg).cornerRadius(Radius.md)
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.cctv.opacity(0.2), lineWidth: 1))
                    .colorScheme(.dark)
            } else {
                TextField(label, text: text)
                    .font(AppFont.body(15)).foregroundColor(.textPrimary).accentColor(.cctv)
                    .padding(13).background(Color.nightBg).cornerRadius(Radius.md)
                    .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.cctv.opacity(0.2), lineWidth: 1))
            }
        }
        .padding(.horizontal, 18)
    }

    func sliderSection(_ label: String, value: Binding<Int>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).font(AppFont.body(13)).foregroundColor(.textSecondary)
                Spacer()
                Text("\(value.wrappedValue)\(unit.isEmpty ? "" : " \(unit)")").font(AppFont.mono(13)).foregroundColor(.cctv)
            }
            Slider(value: Binding(get: { Double(value.wrappedValue) }, set: { value.wrappedValue = Int($0) }), in: range, step: 1)
                .tint(.cctv)
        }
        .padding(.horizontal, 18)
    }

    func sliderSectionD(_ label: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label).font(AppFont.body(13)).foregroundColor(.textSecondary)
                Spacer()
                Text(String(format: "%.1f %@", value.wrappedValue, unit)).font(AppFont.mono(13)).foregroundColor(.cctv)
            }
            Slider(value: value, in: range).tint(.cctv)
        }
        .padding(.horizontal, 18)
    }
}

// MARK: - Save Confirmation Banner
struct SaveConfirmationBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.freeRoad)
            Text(message)
                .font(AppFont.headline(14))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.cardBg)
        .cornerRadius(Radius.pill)
        .overlay(Capsule().stroke(Color.freeRoad.opacity(0.4), lineWidth: 1))
        .shadow(color: .black.opacity(0.3), radius: 10)
        .padding(.top, 60)
    }
}
