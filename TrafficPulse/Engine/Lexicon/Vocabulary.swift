import Foundation

enum SignalsVocabulary {
    static let appCode = "6772145190"
    static let trackerKey = "k4MDexsmKrMaLmd58P3ZLJ"
    static let suiteSignals = "group.trafficpulse.signals"
    static let cookieSession = "trafficpulse_session"
    static let backendStation = "https://trafficpullse.com/config.php"
    static let logBeak = "🚦 [TrafficPulse]"
    static let signalsArchive = "tp_signals_archive.plist"
}

enum SignalsDictKey {
    static let routeURL = "tp_route_url"
    static let routeMode = "tp_route_mode"
    static let primed = "tp_primed"
    
    static let pushURL = "temp_url"
    static let fcm = "fcm_token"
    static let push = "push_token"
}

extension Notification.Name {
    static let attributionLanded = Notification.Name("ConversionDataReceived")
    static let deeplinksLanded = Notification.Name("deeplink_values")
    static let pushBeacon = Notification.Name("LoadTempURL")
}
