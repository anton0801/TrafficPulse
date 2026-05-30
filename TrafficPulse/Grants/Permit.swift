import Foundation
import Combine
import UIKit
import UserNotifications

protocol PermitGrant {
    func solicitPermit() -> Future<Bool, Never>
    func wirePushSensor()
}

final class NotificationPermitGrant: PermitGrant {
    
    func solicitPermit() -> Future<Bool, Never> {
        Future<Bool, Never> { promise in
            let onceGuard = SingleFireGuard()
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                DispatchQueue.main.async {
                    guard onceGuard.tryUse() else { return }
                    promise(.success(granted))
                }
            }
        }
    }
    
    func wirePushSensor() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

final class SingleFireGuard {
    private var fired = false
    private let lock = NSLock()
    
    func tryUse() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !fired else { return false }
        fired = true
        return true
    }
}
