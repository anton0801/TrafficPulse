import Foundation


enum SignalHiccupCode: Int {
    case signalsAbsent = 101
    case packetGarbled = 102
    case unknownSoft = 199
    
    case wireDown = 201
    case throttled = 202
    case timedOut = 203
    case unknownNetwork = 299
    
    case routeBlocked404 = 301
    case routeRefused = 302
    case unknownDenial = 399
    
    var category: String {
        switch self.rawValue {
        case 100..<200: return "soft"
        case 200..<300: return "network"
        case 300..<400: return "denial"
        default: return "unknown"
        }
    }
    
    var isDenial: Bool { self.rawValue >= 300 && self.rawValue < 400 }
    var isNetwork: Bool { self.rawValue >= 200 && self.rawValue < 300 }
}

struct SignalHiccup: Error, CustomStringConvertible {
    let code: SignalHiccupCode
    let stage: String
    let context: String?
    let timestamp: Date
    
    init(_ code: SignalHiccupCode, stage: String, context: String? = nil) {
        self.code = code
        self.stage = stage
        self.context = context
        self.timestamp = Date()
    }
    
    var description: String {
        let ctx = context.map { " ctx=\($0)" } ?? ""
        return "SignalHiccup[\(code.rawValue):\(code.category)]@\(stage)\(ctx)"
    }
    
    var isDenial: Bool { code.isDenial }
}

struct ThrottleHint {
    let retryAfterSeconds: TimeInterval
}
