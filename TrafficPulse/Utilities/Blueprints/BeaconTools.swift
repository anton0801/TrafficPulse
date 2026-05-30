import Foundation

// MARK: - Signals Archive (persisted)

struct SignalsArchive: Codable {
    let blips: [String: String]
    let lights: [String: String]
    let routeURL: String?
    let routeMode: String?
    let unscanned: Bool
    let consentGreenlit: Bool
    let consentRedflagged: Bool
    let consentStampedAt: Date?
}

struct Beacon {
    var blips: [String: String] = [:]
    var lights: [String: String] = [:]
    var routeURL: String? = nil
    var routeMode: String? = nil
    var unscanned: Bool = true
    var anchored: Bool = false
    var organicCovered: Bool = false
    var consentGreenlit: Bool = false
    var consentRedflagged: Bool = false
    var consentStampedAt: Date? = nil
    
    var blipsReady: Bool { !blips.isEmpty }
    var organicLane: Bool { blips["af_status"] == "Organic" }
    
    var consentRipe: Bool {
        guard !consentGreenlit && !consentRedflagged else { return false }
        if let date = consentStampedAt {
            let elapsed = Date().timeIntervalSince(date) / 86400
            return elapsed >= 3
        }
        return true
    }
    
    static func revive(from archive: SignalsArchive) -> Beacon {
        var b = Beacon()
        b.blips = archive.blips
        b.lights = archive.lights
        b.routeURL = archive.routeURL
        b.routeMode = archive.routeMode
        b.unscanned = archive.unscanned
        b.consentGreenlit = archive.consentGreenlit
        b.consentRedflagged = archive.consentRedflagged
        b.consentStampedAt = archive.consentStampedAt
        return b
    }
    
    func entomb() -> SignalsArchive {
        SignalsArchive(
            blips: blips, lights: lights,
            routeURL: routeURL, routeMode: routeMode,
            unscanned: unscanned,
            consentGreenlit: consentGreenlit, consentRedflagged: consentRedflagged,
            consentStampedAt: consentStampedAt
        )
    }
}

enum PulseOutcome: Equatable {
    case standby
    case askConsent
    case openShowcase
    case sidelined
}
