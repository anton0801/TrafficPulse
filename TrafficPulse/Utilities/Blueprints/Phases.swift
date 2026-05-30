import Foundation

enum SignalPhase: String {
    case dormant
    case revived
    case ignited
    case routing
    case anchored
    case stalled
    case terminus
}

enum PhaseEvent {
    case wakeRequested
    case archiveLoaded(Beacon)
    case blipsHarvested([String: String])
    case lightsHarvested([String: String])
    case pulseInitiated
    case pushIntercepted(String)
    case organicTouched
    case organicResolved([String: String])
    case routingStarted
    case routeAnchored(String)
    case routeBlocked(SignalHiccup)
    case consentSolicited
    case consentSettled(granted: Bool)
    case consentDeferred
    case deadlineStruck
}

enum PhaseEffect {
    case persistBeacon
    case stampStorageRoute(url: String, mode: String)
    case primeFlag
    case clearPushURL
    case launchOrganicRefetch
    case launchRoutingQuery
    case launchConsentDialog
    case enablePushReceiver
    case publishOutcome(PulseOutcome)
}
