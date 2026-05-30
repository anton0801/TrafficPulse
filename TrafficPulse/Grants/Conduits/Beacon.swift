import Foundation
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit

protocol BeaconProbe {
    func interrogate(seed: [String: Any]) async throws -> String
}

final class HTTPBeaconProbe: BeaconProbe {
    
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    private let breathers: [Double] = [94.0, 188.0, 376.0]
    
    func interrogate(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: SignalsVocabulary.backendStation) else {
            throw SignalHiccup(.packetGarbled, stage: "beacon.url")
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["store_id"] = "id\(SignalsVocabulary.appCode)"
        body["push_token"] = UserDefaults.standard.string(forKey: SignalsDictKey.push)
            ?? Messaging.messaging().fcmToken
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastHiccup: Error?
        
        for (idx, breather) in breathers.enumerated() {
            do {
                return try await fireSingle(request)
            } catch let hiccup as SignalHiccup {
                if hiccup.isDenial {
                    throw hiccup
                }
                lastHiccup = hiccup
                if idx < breathers.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(breather * 1_000_000_000))
                }
            } catch let hint as ThrottleHint {
                try await Task.sleep(nanoseconds: UInt64(hint.retryAfterSeconds * 1_000_000_000))
                continue
            } catch {
                lastHiccup = error
                if idx < breathers.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(breather * 1_000_000_000))
                }
            }
        }
        
        if let lastHiccup = lastHiccup {
            throw lastHiccup
        }
        throw SignalHiccup(.wireDown, stage: "beacon.exhausted")
    }
    
    private func fireSingle(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw SignalHiccup(.wireDown, stage: "beacon.response")
        }
        
        if http.statusCode == 404 {
            throw SignalHiccup(.routeBlocked404, stage: "beacon.404")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SignalHiccup(.packetGarbled, stage: "beacon.json")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw SignalHiccup(.packetGarbled, stage: "beacon.missingOk")
        }
        
        if !ok {
            throw SignalHiccup(.routeRefused, stage: "beacon.okFalse")
        }
        
        guard let url = json["url"] as? String, !url.isEmpty else {
            throw SignalHiccup(.packetGarbled, stage: "beacon.missingURL")
        }
        
        return url
    }
}

extension ThrottleHint: Error {}
