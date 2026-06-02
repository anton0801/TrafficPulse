import SwiftUI
import Foundation
import UserNotifications

// MARK: - App State (EnvironmentObject)
class AppState: ObservableObject {
    @AppStorage("colorTheme") var colorTheme: String = "dark" {
        didSet { objectWillChange.send() }
    }
    @AppStorage("animationSpeed") var animationSpeed: Double = 1.0
    @AppStorage("distanceUnit") var distanceUnit: String = "km"
    @AppStorage("fuelUnit") var fuelUnit: String = "L"
    @AppStorage("language") var language: String = "English"
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true

    var preferredColorScheme: ColorScheme? {
        switch colorTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

// MARK: - Trip ViewModel
class TripViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var selectedTrip: Trip?
    @Published var isAddingTrip = false
    @Published var filterStatus: TripStatus? = nil

    private let storageKey = "saved_trips"

    init() { load() }

    var filteredTrips: [Trip] {
        if let f = filterStatus { return trips.filter { $0.status == f } }
        return trips.sorted { $0.date > $1.date }
    }

    var todayTrips: [Trip] {
        let cal = Calendar.current
        return trips.filter { cal.isDateInToday($0.date) }
    }

    var totalDelayToday: Int {
        todayTrips.reduce(0) { $0 + $1.delayMinutes }
    }

    var avgScoreToday: Int {
        guard !todayTrips.isEmpty else { return 0 }
        return todayTrips.reduce(0) { $0 + $1.trafficScore } / todayTrips.count
    }

    var weeklyStats: WeeklyStats {
        let cal = Calendar.current
        let weekAgo = cal.date(byAdding: .day, value: -7, to: Date())!
        let weekTrips = trips.filter { $0.date >= weekAgo }
        guard !weekTrips.isEmpty else { return .empty }

        // find bussiest day
        var dayCountMap: [String: Int] = [:]
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        for t in weekTrips {
            let d = dayFormatter.string(from: t.date)
            dayCountMap[d, default: 0] += 1
        }
        let bussiestDay = dayCountMap.max(by: { $0.value < $1.value })?.key ?? "—"

        // find best day (highest avg score)
        var dayScoreMap: [String: [Int]] = [:]
        for t in weekTrips {
            let d = dayFormatter.string(from: t.date)
            dayScoreMap[d, default: []].append(t.trafficScore)
        }
        let bestDay = dayScoreMap.mapValues { $0.reduce(0, +) / $0.count }
            .max(by: { $0.value < $1.value })?.key ?? "—"

        return WeeklyStats(
            totalTrips: weekTrips.count,
            totalDistanceKm: weekTrips.reduce(0) { $0 + $1.distanceKm },
            totalDelayMinutes: weekTrips.reduce(0) { $0 + $1.delayMinutes },
            avgTrafficScore: weekTrips.reduce(0) { $0 + $1.trafficScore } / weekTrips.count,
            totalFuelCost: 0,
            bussiestDay: bussiestDay,
            bestDay: bestDay
        )
    }

    var weekly2Stats: WeeklyStats {
        let cal = Calendar.current
        let weekAgo = cal.date(byAdding: .day, value: -14, to: Date())!
        let weekTrips = trips.filter { $0.date >= weekAgo }
        guard !weekTrips.isEmpty else { return .empty }

        // find bussiest day
        var dayCountMap: [String: Int] = [:]
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        for t in weekTrips {
            let d = dayFormatter.string(from: t.date)
            dayCountMap[d, default: 0] += 1
        }
        let bussiestDay = dayCountMap.max(by: { $0.value < $1.value })?.key ?? "—"

        // find best day (highest avg score)
        var dayScoreMap: [String: [Int]] = [:]
        for t in weekTrips {
            let d = dayFormatter.string(from: t.date)
            dayScoreMap[d, default: []].append(t.trafficScore)
        }
        let bestDay = dayScoreMap.mapValues { $0.reduce(0, +) / $0.count }
            .max(by: { $0.value < $1.value })?.key ?? "—"

        return WeeklyStats(
            totalTrips: weekTrips.count,
            totalDistanceKm: weekTrips.reduce(0) { $0 + $1.distanceKm },
            totalDelayMinutes: weekTrips.reduce(0) { $0 + $1.delayMinutes },
            avgTrafficScore: weekTrips.reduce(0) { $0 + $1.trafficScore } / weekTrips.count,
            totalFuelCost: 0,
            bussiestDay: bussiestDay,
            bestDay: bestDay
        )
    }

    // day-by-day scores for chart (last 7 days)
    func dailyScores() -> [(String, Double)] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).reversed().map { offset -> (String, Double) in
            let day = cal.date(byAdding: .day, value: -offset, to: Date())!
            let dayStr = formatter.string(from: day)
            let dayTrips = trips.filter { cal.isDate($0.date, inSameDayAs: day) }
            let avg = dayTrips.isEmpty ? 0.0 : Double(dayTrips.reduce(0) { $0 + $1.trafficScore }) / Double(dayTrips.count)
            return (dayStr, avg)
        }
    }


    // day-by-day scores for chart (last 7 days)
    func dailyScordases() -> [(String, Double)] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<9).reversed().map { offset -> (String, Double) in
            let day = cal.date(byAdding: .day, value: -offset, to: Date())!
            let dayStr = formatter.string(from: day)
            let dayTrips = trips.filter { cal.isDate($0.date, inSameDayAs: day) }
            let avg = dayTrips.isEmpty ? 0.0 : Double(dayTrips.reduce(0) { $0 + $1.trafficScore }) / Double(dayTrips.count)
            return (dayStr, avg)
        }
    }

    func delayByDay() -> [(String, Double)] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).reversed().map { offset -> (String, Double) in
            let day = cal.date(byAdding: .day, value: -offset, to: Date())!
            let dayStr = formatter.string(from: day)
            let dayTrips = trips.filter { cal.isDate($0.date, inSameDayAs: day) }
            let total = Double(dayTrips.reduce(0) { $0 + $1.delayMinutes })
            return (dayStr, total)
        }
    }

    func add(_ trip: Trip) {
        trips.insert(trip, at: 0)
        save()
    }

    func update(_ trip: Trip) {
        if let idx = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[idx] = trip
            save()
        }
    }

    func delete(at offsets: IndexSet) {
        trips.remove(atOffsets: offsets)
        save()
    }

    func delete(_ trip: Trip) {
        trips.removeAll { $0.id == trip.id }
        save()
    }

    func duplicate(_ trip: Trip) {
        var copy = trip
        copy.id = UUID()
        copy.name = trip.name + " (Copy)"
        copy.date = Date()
        trips.insert(copy, at: 0)
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(trips) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Trip].self, from: data) {
            trips = decoded
        } else {
            trips = SampleData.generateTrips()
            save()
        }
    }
}

// MARK: - Route ViewModel
class RouteViewModel: ObservableObject {
    @Published var routes: [Route] = []
    @Published var isAddingRoute = false
    @Published var selectedRoute: Route?

    private let storageKey = "saved_routes"

    init() { load() }

    var favoriteRoutes: [Route] { routes.filter { $0.isFavorite } }

    func add(_ route: Route) {
        routes.insert(route, at: 0)
        save()
    }

    func update(_ route: Route) {
        if let idx = routes.firstIndex(where: { $0.id == route.id }) {
            routes[idx] = route
            save()
        }
    }

    func delete(_ route: Route) {
        routes.removeAll { $0.id == route.id }
        save()
    }

    func toggleFavorite(_ route: Route) {
        if let idx = routes.firstIndex(where: { $0.id == route.id }) {
            routes[idx].isFavorite.toggle()
            save()
        }
    }

    func incrementUse(_ route: Route) {
        if let idx = routes.firstIndex(where: { $0.id == route.id }) {
            routes[idx].useCount += 1
            routes[idx].lastUsed = Date()
            save()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(routes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([Route].self, from: data) {
            routes = decoded
        } else {
            routes = SampleData.generateRoutes()
            save()
        }
    }
}

// MARK: - Fuel ViewModel
class FuelViewModel: ObservableObject {
    @Published var entries: [FuelEntry] = []
    @Published var isAddingEntry = false

    private let storageKey = "saved_fuel"

    init() { load() }

    var totalCost: Double { entries.reduce(0) { $0 + $1.totalCost } }
    var totalLiters: Double { entries.reduce(0) { $0 + $1.liters } }
    var avgPrice: Double {
        guard !entries.isEmpty else { return 0 }
        return totalCost / totalLiters
    }

    func add(_ entry: FuelEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func delete(_ entry: FuelEntry) {
        entries.removeAll { $0.id == entry.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([FuelEntry].self, from: data) {
            entries = decoded
        } else {
            entries = SampleData.generateFuelEntries()
            save()
        }
    }
}

// MARK: - Traffic ViewModel
class TrafficViewModel: ObservableObject {
    @Published var events: [TrafficEvent] = []
    @Published var currentScore: Int = 72
    @Published var isRefreshing = false

    private let storageKey = "saved_traffic_events"

    init() { load() }

    var currentStatus: String {
        switch currentScore {
        case 0..<40: return "Heavy Traffic"
        case 40..<70: return "Moderate"
        default: return "Clear Roads"
        }
    }

    var statusColor: Color { trafficColor(currentScore) }

    func simulateRefresh() {
        isRefreshing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.currentScore = Int.random(in: 40...95)
            self.isRefreshing = false
        }
    }

    func addEvent(_ event: TrafficEvent) {
        events.insert(event, at: 0)
        save()
    }

    func delete(_ event: TrafficEvent) {
        events.removeAll { $0.id == event.id }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([TrafficEvent].self, from: data) {
            events = decoded
        } else {
            events = SampleData.generateTrafficEvents()
            save()
        }
    }
}

// MARK: - Notification ViewModel
class NotificationViewModel: ObservableObject {
    @Published var schedule = NotificationSchedule()
    private let storageKey = "notification_schedule"

    init() { load() }

    func saveAndSchedule() {
        save()
        guard schedule.isEnabled else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            guard granted, let self = self else { return }
            DispatchQueue.main.async { self.scheduleAll() }
        }
    }

    private func scheduleAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        if schedule.morningAlert {
            schedule(id: "morning_traffic",
                     title: "🚦 Morning Traffic Update",
                     body: "Check your route before heading out.",
                     time: schedule.morningTime,
                     repeats: true)
        }
        if schedule.eveningAlert {
            schedule(id: "evening_traffic",
                     title: "🚗 Evening Rush Hour",
                     body: "Plan your route home — delays possible.",
                     time: schedule.eveningTime,
                     repeats: true)
        }
        if schedule.weeklyReport {
            scheduleWeekly(id: "weekly_report",
                           title: "📊 Weekly Traffic Report",
                           body: "Your driving stats for the week are ready.")
        }
    }

    private func schedule(id: String, title: String, body: String, time: Date, repeats: Bool) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: repeats)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleWeekly(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.weekday = 2  // Monday
        components.hour = 9
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(schedule) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(NotificationSchedule.self, from: data) {
            schedule = decoded
        }
    }
}

// MARK: - Recommendations ViewModel
class RecommendationsViewModel: ObservableObject {
    @Published var recommendations: [Recommendation] = []
    @Published var addedToTasks: Set<UUID> = []

    init() { generate() }

    func generate() {
        recommendations = [
            Recommendation(title: "Avoid Peak Hours", description: "Your data shows highest delays between 8–9 AM. Consider leaving 20 min earlier.", icon: "clock.badge.exclamationmark.fill", priority: .high, category: "Schedule"),
            Recommendation(title: "Alternate Route Detected", description: "City Loop route shows 15% lower congestion on Thursdays vs your usual commute.", icon: "map.fill", priority: .high, category: "Route"),
            Recommendation(title: "Fuel Efficiency Tip", description: "Smooth acceleration on free roads can reduce fuel use by up to 12%.", icon: "fuelpump.fill", priority: .medium, category: "Fuel"),
            Recommendation(title: "Check Traffic Before 5 PM", description: "Your Evening Return trips show consistent delays. Refresh traffic 30 min before departure.", icon: "exclamationmark.triangle.fill", priority: .medium, category: "Timing"),
            Recommendation(title: "Log More Fuel Data", description: "Only 3 fuel entries found. More data will improve cost-per-km accuracy.", icon: "chart.bar.fill", priority: .low, category: "Data"),
            Recommendation(title: "Airport Route Timing", description: "Your Airport trips average 18 min delay. Consider a 45-min buffer for early flights.", icon: "airplane.fill", priority: .medium, category: "Planning")
        ]
    }

    func markAdded(_ id: UUID) {
        addedToTasks.insert(id)
    }

    func isAdded(_ id: UUID) -> Bool {
        addedToTasks.contains(id)
    }
}
