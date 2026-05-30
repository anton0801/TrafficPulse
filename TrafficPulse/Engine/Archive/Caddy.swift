import Foundation

protocol SignalsCaddy {
    func storeArchive(_ archive: SignalsArchive)
    func recordRoute(url: String, mode: String)
    func raisePrimedFlag()
    func retrieveArchive() -> SignalsArchive
}

final class MiniLRU<Key: Hashable, Value> {
    private var store: [Key: Value] = [:]
    private var order: [Key] = []
    private let capacity: Int
    private let lock = NSLock()
    
    init(capacity: Int) {
        self.capacity = capacity
    }
    
    func put(_ key: Key, _ value: Value) {
        lock.lock()
        defer { lock.unlock() }
        if store[key] != nil {
            order.removeAll { $0 == key }
        } else if store.count >= capacity {
            if let oldest = order.first {
                store.removeValue(forKey: oldest)
                order.removeFirst()
            }
        }
        store[key] = value
        order.append(key)
    }
    
    func get(_ key: Key) -> Value? {
        lock.lock()
        defer { lock.unlock() }
        guard let value = store[key] else { return nil }
        order.removeAll { $0 == key }
        order.append(key)
        return value
    }
    
    func invalidate() {
        lock.lock()
        defer { lock.unlock() }
        store.removeAll()
        order.removeAll()
    }
}

final class PlistCaddy: SignalsCaddy {
    
    private let fm = FileManager.default
    private let dataDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults
    
    private let lru: MiniLRU<String, SignalsArchive>
    private let cacheKey = "current"
    
    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.dataDir = docs.appendingPathComponent("TrafficSignals", isDirectory: true)
        if !fm.fileExists(atPath: dataDir.path) {
            try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
        }
        
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: SignalsVocabulary.suiteSignals) ?? .standard
        self.lru = MiniLRU<String, SignalsArchive>(capacity: 3)
    }
    
    private var plistURL: URL {
        dataDir.appendingPathComponent(SignalsVocabulary.signalsArchive)
    }
    
    func storeArchive(_ archive: SignalsArchive) {
        let veiled = VeiledSignals(
            blips: veilDict(archive.blips),
            lights: veilDict(archive.lights),
            routeURL: archive.routeURL,
            routeMode: archive.routeMode,
            unscanned: archive.unscanned,
            consentGreenlit: archive.consentGreenlit,
            consentRedflagged: archive.consentRedflagged,
            consentStampedAt: archive.consentStampedAt
        )
        
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        
        do {
            let data = try encoder.encode(veiled)
            try data.write(to: plistURL, options: .atomic)
            
            // Update LRU
            lru.put(cacheKey, archive)
        } catch {
        }
    }
    
    func recordRoute(url: String, mode: String) {
        suiteStore.set(url, forKey: SignalsDictKey.routeURL)
        homeStore.set(url, forKey: SignalsDictKey.routeURL)
        suiteStore.set(mode, forKey: SignalsDictKey.routeMode)
    }
    
    func raisePrimedFlag() {
        suiteStore.set(true, forKey: SignalsDictKey.primed)
        homeStore.set(true, forKey: SignalsDictKey.primed)
    }
    
    func retrieveArchive() -> SignalsArchive {
        // Try LRU cache first
        if let cached = lru.get(cacheKey) {
            return cached
        }
        
        // Read from plist
        guard fm.fileExists(atPath: plistURL.path),
              let data = try? Data(contentsOf: plistURL) else {
            return fromDefaults()
        }
        
        let decoder = PropertyListDecoder()
        
        guard let veiled = try? decoder.decode(VeiledSignals.self, from: data) else {
            return fromDefaults()
        }
        
        let archive = SignalsArchive(
            blips: unveilDict(veiled.blips),
            lights: unveilDict(veiled.lights),
            routeURL: veiled.routeURL,
            routeMode: veiled.routeMode,
            unscanned: veiled.unscanned,
            consentGreenlit: veiled.consentGreenlit,
            consentRedflagged: veiled.consentRedflagged,
            consentStampedAt: veiled.consentStampedAt
        )
        
        lru.put(cacheKey, archive)
        return archive
    }
    
    private func fromDefaults() -> SignalsArchive {
        let routeURL = homeStore.string(forKey: SignalsDictKey.routeURL)
            ?? suiteStore.string(forKey: SignalsDictKey.routeURL)
        let routeMode = suiteStore.string(forKey: SignalsDictKey.routeMode)
        let primed = suiteStore.bool(forKey: SignalsDictKey.primed)
        
        return SignalsArchive(
            blips: [:], lights: [:],
            routeURL: routeURL, routeMode: routeMode,
            unscanned: !primed,
            consentGreenlit: false, consentRedflagged: false, consentStampedAt: nil
        )
    }
    
    private func veilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = veil(v) }
        return result
    }
    
    private func unveilDict(_ dict: [String: String]) -> [String: String] {
        var result: [String: String] = [:]
        for (k, v) in dict { result[k] = unveil(v) ?? v }
        return result
    }
    
    private func veil(_ input: String) -> String {
        let b64 = Data(input.utf8).base64EncodedString()
        return b64
            .replacingOccurrences(of: "+", with: ";")
            .replacingOccurrences(of: "/", with: ",")
    }
    
    private func unveil(_ input: String) -> String? {
        let b64 = input
            .replacingOccurrences(of: ";", with: "+")
            .replacingOccurrences(of: ",", with: "/")
        guard let data = Data(base64Encoded: b64),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct VeiledSignals: Codable {
    let blips: [String: String]
    let lights: [String: String]
    let routeURL: String?
    let routeMode: String?
    let unscanned: Bool
    let consentGreenlit: Bool
    let consentRedflagged: Bool
    let consentStampedAt: Date?
}
