import SwiftUI
import Foundation

// MARK: - Trip Model
struct Trip: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var origin: String
    var destination: String
    var date: Date
    var durationMinutes: Int
    var delayMinutes: Int
    var distanceKm: Double
    var trafficScore: Int       // 0-100
    var fuelUsed: Double        // liters
    var notes: String
    var status: TripStatus
    var congestionSegments: [CongestionSegment]

    static func == (lhs: Trip, rhs: Trip) -> Bool { lhs.id == rhs.id }

    var delayCategory: DelayCategory {
        switch delayMinutes {
        case 0..<5: return .none
        case 5..<15: return .minor
        case 15..<30: return .moderate
        default: return .severe
        }
    }
}

enum TripStatus: String, Codable, CaseIterable {
    case completed = "Completed"
    case inProgress = "In Progress"
    case planned = "Planned"

    var color: Color {
        switch self {
        case .completed: return .freeRoad
        case .inProgress: return .activeFlow
        case .planned: return .cctv
        }
    }

    var icon: String {
        switch self {
        case .completed: return "checkmark.circle.fill"
        case .inProgress: return "car.fill"
        case .planned: return "clock.fill"
        }
    }
}

enum DelayCategory: String {
    case none = "On Time"
    case minor = "Slight Delay"
    case moderate = "Moderate"
    case severe = "Heavy Delay"

    var color: Color {
        switch self {
        case .none: return .freeRoad
        case .minor: return .warning
        case .moderate: return .activeFlow
        case .severe: return .congestion
        }
    }
}

struct CongestionSegment: Identifiable, Codable {
    var id = UUID()
    var name: String
    var delayMinutes: Int
    var severity: Int   // 1-3
}

// MARK: - Route Model
struct Route: Identifiable, Codable {
    var id = UUID()
    var name: String
    var origin: String
    var destination: String
    var waypoints: [String]
    var estimatedMinutes: Int
    var distanceKm: Double
    var lastUsed: Date?
    var useCount: Int = 0
    var avgTrafficScore: Int = 75
    var isFavorite: Bool = false
}

// MARK: - Fuel Entry
struct FuelEntry: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var liters: Double
    var pricePerLiter: Double
    var totalCost: Double
    var odometer: Double
    var station: String
    var notes: String

    var costPerKm: Double? {
        guard totalCost > 0, odometer > 0 else { return nil }
        return totalCost / odometer
    }
}

// MARK: - Traffic Event
struct TrafficEvent: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var location: String
    var type: TrafficEventType
    var durationMinutes: Int
    var severity: Int
    var description: String
}

enum TrafficEventType: String, Codable, CaseIterable {
    case accident = "Accident"
    case construction = "Construction"
    case congestion = "Congestion"
    case roadwork = "Roadwork"
    case closure = "Closure"

    var icon: String {
        switch self {
        case .accident: return "exclamationmark.triangle.fill"
        case .construction: return "hammer.fill"
        case .congestion: return "car.2.fill"
        case .roadwork: return "cone.fill"
        case .closure: return "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .accident: return .congestion
        case .construction: return .warning
        case .congestion: return .activeFlow
        case .roadwork: return .warning
        case .closure: return .congestion
        }
    }
}

// MARK: - Recommendation
struct Recommendation: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var icon: String
    var priority: RecommendationPriority
    var category: String
}

enum RecommendationPriority: String, CaseIterable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var color: Color {
        switch self {
        case .high: return .congestion
        case .medium: return .warning
        case .low: return .freeRoad
        }
    }
}

// MARK: - Notification Schedule
struct NotificationSchedule: Codable {
    var isEnabled: Bool = true
    var morningAlert: Bool = true
    var morningTime: Date = Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date()
    var eveningAlert: Bool = true
    var eveningTime: Date = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    var tripReminder: Bool = true
    var weeklyReport: Bool = true
}

// MARK: - Weekly Stats
struct WeeklyStats {
    var totalTrips: Int
    var totalDistanceKm: Double
    var totalDelayMinutes: Int
    var avgTrafficScore: Int
    var totalFuelCost: Double
    var bussiestDay: String
    var bestDay: String

    static var empty: WeeklyStats {
        WeeklyStats(totalTrips: 0, totalDistanceKm: 0, totalDelayMinutes: 0, avgTrafficScore: 0, totalFuelCost: 0, bussiestDay: "—", bestDay: "—")
    }
}

// MARK: - Sample Data Generator
struct SampleData {
    static func generateTrips() -> [Trip] {
        let calendar = Calendar.current
        let now = Date()
        return [
            Trip(name: "Morning Commute", origin: "Home", destination: "Office", date: calendar.date(byAdding: .hour, value: -3, to: now)!, durationMinutes: 42, delayMinutes: 12, distanceKm: 18.5, trafficScore: 55, fuelUsed: 2.1, notes: "Heavy traffic on Main St", status: .completed, congestionSegments: [CongestionSegment(name: "Main St / Bridge", delayMinutes: 8, severity: 2), CongestionSegment(name: "City Center Ring", delayMinutes: 4, severity: 1)]),
            Trip(name: "Grocery Run", origin: "Office", destination: "Supermarket", date: calendar.date(byAdding: .hour, value: -1, to: now)!, durationMinutes: 18, delayMinutes: 3, distanceKm: 6.2, trafficScore: 82, fuelUsed: 0.7, notes: "", status: .completed, congestionSegments: []),
            Trip(name: "Evening Return", origin: "Office", destination: "Home", date: calendar.date(byAdding: .minute, value: -30, to: now)!, durationMinutes: 55, delayMinutes: 22, distanceKm: 18.5, trafficScore: 38, fuelUsed: 2.4, notes: "Accident on bypass road", status: .inProgress, congestionSegments: [CongestionSegment(name: "Bypass Road", delayMinutes: 15, severity: 3), CongestionSegment(name: "Industrial Zone", delayMinutes: 7, severity: 2)]),
            Trip(name: "Client Visit", origin: "Home", destination: "Business Park", date: calendar.date(byAdding: .day, value: -1, to: now)!, durationMinutes: 35, delayMinutes: 0, distanceKm: 14.3, trafficScore: 91, fuelUsed: 1.6, notes: "Great flow today", status: .completed, congestionSegments: []),
            Trip(name: "Airport Drop", origin: "Home", destination: "Airport", date: calendar.date(byAdding: .day, value: -2, to: now)!, durationMinutes: 62, delayMinutes: 18, distanceKm: 32.1, trafficScore: 61, fuelUsed: 3.8, notes: "Construction zone slowed us", status: .completed, congestionSegments: [CongestionSegment(name: "Highway 4 Construction", delayMinutes: 18, severity: 2)]),
            Trip(name: "Weekend Trip", origin: "Home", destination: "Mall", date: calendar.date(byAdding: .day, value: 1, to: now)!, durationMinutes: 25, delayMinutes: 0, distanceKm: 9.5, trafficScore: 85, fuelUsed: 1.1, notes: "", status: .planned, congestionSegments: [])
        ]
    }

    static func generateRoutes() -> [Route] {
        [
            Route(name: "Daily Commute", origin: "Home", destination: "Office", waypoints: ["Main St", "Bridge Ave"], estimatedMinutes: 35, distanceKm: 18.5, lastUsed: Date(), useCount: 48, avgTrafficScore: 62, isFavorite: true),
            Route(name: "City Loop", origin: "Office", destination: "Office", waypoints: ["Market St", "Harbor Rd", "North Ring"], estimatedMinutes: 25, distanceKm: 12.0, lastUsed: Calendar.current.date(byAdding: .day, value: -3, to: Date()), useCount: 12, avgTrafficScore: 74, isFavorite: false),
            Route(name: "Airport Express", origin: "Home", destination: "Airport", waypoints: ["Highway 4", "Ring Road"], estimatedMinutes: 45, distanceKm: 32.1, lastUsed: Calendar.current.date(byAdding: .day, value: -7, to: Date()), useCount: 6, avgTrafficScore: 70, isFavorite: true)
        ]
    }

    static func generateFuelEntries() -> [FuelEntry] {
        let cal = Calendar.current
        let now = Date()
        return [
            FuelEntry(date: now, liters: 42.5, pricePerLiter: 1.65, totalCost: 70.13, odometer: 74820, station: "BP Station Center", notes: "Full tank"),
            FuelEntry(date: cal.date(byAdding: .day, value: -7, to: now)!, liters: 38.2, pricePerLiter: 1.62, totalCost: 61.88, odometer: 74430, station: "Shell Highway", notes: ""),
            FuelEntry(date: cal.date(byAdding: .day, value: -14, to: now)!, liters: 45.0, pricePerLiter: 1.68, totalCost: 75.60, odometer: 73990, station: "Total Energy", notes: "Discount card used")
        ]
    }

    static func generateTrafficEvents() -> [TrafficEvent] {
        let now = Date()
        let cal = Calendar.current
        return [
            TrafficEvent(date: now, location: "Main St & 5th Ave", type: .accident, durationMinutes: 45, severity: 3, description: "Multi-vehicle collision blocking two lanes"),
            TrafficEvent(date: cal.date(byAdding: .hour, value: -2, to: now)!, location: "City Center Ring", type: .congestion, durationMinutes: 90, severity: 2, description: "Rush hour peak congestion"),
            TrafficEvent(date: cal.date(byAdding: .hour, value: -5, to: now)!, location: "Highway 4 km 12", type: .construction, durationMinutes: 480, severity: 1, description: "Road resurfacing, lane reduced"),
            TrafficEvent(date: cal.date(byAdding: .day, value: -1, to: now)!, location: "Bridge Road", type: .roadwork, durationMinutes: 120, severity: 2, description: "Bridge maintenance work")
        ]
    }
}
