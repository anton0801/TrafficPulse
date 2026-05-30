import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private lazy var lifecycleHandler: LifecycleHandler = {
        Assembler.shared.bootstrapProduction()
        
        let core = CoreDelegate(host: self)
        let firebase = FirebaseDecorator(wrapped: core)
        let messaging = MessagingDecorator(wrapped: firebase, host: self)
        let notifications = NotificationsDecorator(wrapped: messaging, host: self)
        let appsFlyer = AppsFlyerDecorator(wrapped: notifications, host: self)
        let fusion = FusionDecorator(wrapped: appsFlyer)
        return fusion
    }()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        lifecycleHandler.handleLaunch(launchOptions: launchOptions)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        lifecycleHandler.handleActivation()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: SignalsDictKey.fcm)
            UserDefaults.standard.set(t, forKey: SignalsDictKey.push)
            UserDefaults(suiteName: SignalsVocabulary.suiteSignals)?.set(t, forKey: "shared_fcm")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        lifecycleHandler.handlePushPayload(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        lifecycleHandler.handlePushPayload(response.notification.request.content.userInfo)
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        lifecycleHandler.handlePushPayload(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        lifecycleHandler.handleBlips(data)
    }
    
    func onConversionDataFail(_ error: Error) {
        lifecycleHandler.handleBlips([
            "error": true,
            "error_desc": error.localizedDescription
        ])
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        lifecycleHandler.handleLights(link.clickEvent)
    }
}

protocol LifecycleHandler: AnyObject {
    func handleLaunch(launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
    func handleActivation()
    func handleBlips(_ data: [AnyHashable: Any])
    func handleLights(_ data: [AnyHashable: Any])
    func handlePushPayload(_ payload: [AnyHashable: Any])
}

final class CoreDelegate: LifecycleHandler {
    private weak var host: AppDelegate?
    
    init(host: AppDelegate) {
        self.host = host
    }
    
    func handleLaunch(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            handlePushPayload(remote)
        }
    }
    
    func handleActivation() {
    }
    
    func handleBlips(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .attributionLanded,
            object: nil,
            userInfo: ["conversionData": data]
        )
    }
    
    func handleLights(_ data: [AnyHashable: Any]) {
        NotificationCenter.default.post(
            name: .deeplinksLanded,
            object: nil,
            userInfo: ["deeplinksData": data]
        )
    }
    
    func handlePushPayload(_ payload: [AnyHashable: Any]) {
        guard let url = extractURL(payload) else { return }
        UserDefaults.standard.set(url, forKey: SignalsDictKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            NotificationCenter.default.post(
                name: .pushBeacon,
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extractURL(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
}

class BaseDecorator: LifecycleHandler {
    let wrapped: LifecycleHandler
    
    init(wrapped: LifecycleHandler) {
        self.wrapped = wrapped
    }
    
    func handleLaunch(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        wrapped.handleLaunch(launchOptions: launchOptions)
    }
    
    func handleActivation() { wrapped.handleActivation() }
    func handleBlips(_ data: [AnyHashable: Any]) { wrapped.handleBlips(data) }
    func handleLights(_ data: [AnyHashable: Any]) { wrapped.handleLights(data) }
    func handlePushPayload(_ payload: [AnyHashable: Any]) { wrapped.handlePushPayload(payload) }
}

final class FirebaseDecorator: BaseDecorator {
    override func handleLaunch(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        FirebaseApp.configure()
        super.handleLaunch(launchOptions: launchOptions)
    }
}

final class MessagingDecorator: BaseDecorator {
    private weak var host: MessagingDelegate?
    
    init(wrapped: LifecycleHandler, host: MessagingDelegate) {
        self.host = host
        super.init(wrapped: wrapped)
    }
    
    override func handleLaunch(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        Messaging.messaging().delegate = host
        UIApplication.shared.registerForRemoteNotifications()
        super.handleLaunch(launchOptions: launchOptions)
    }
}

final class NotificationsDecorator: BaseDecorator {
    private weak var host: UNUserNotificationCenterDelegate?
    
    init(wrapped: LifecycleHandler, host: UNUserNotificationCenterDelegate) {
        self.host = host
        super.init(wrapped: wrapped)
    }
    
    override func handleLaunch(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        UNUserNotificationCenter.current().delegate = host
        super.handleLaunch(launchOptions: launchOptions)
    }
}

final class AppsFlyerDecorator: BaseDecorator {
    private weak var attDelegate: AppsFlyerLibDelegate?
    private weak var linkDelegate: DeepLinkDelegate?
    
    init(wrapped: LifecycleHandler, host: AppDelegate) {
        self.attDelegate = host
        self.linkDelegate = host
        super.init(wrapped: wrapped)
    }
    
    override func handleLaunch(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = SignalsVocabulary.trackerKey
        sdk.appleAppID = SignalsVocabulary.appCode
        sdk.delegate = attDelegate
        sdk.deepLinkDelegate = linkDelegate
        sdk.isDebug = false
        super.handleLaunch(launchOptions: launchOptions)
    }
    
    override func handleActivation() {
        super.handleActivation()
        startAttribution()
    }
    
    private func startAttribution() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

final class FusionDecorator: BaseDecorator {
    
    private var blipsBuffer: [AnyHashable: Any] = [:]
    private var lightsBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    override func handleBlips(_ data: [AnyHashable: Any]) {
        blipsBuffer = data
        scheduleFuse()
        if !lightsBuffer.isEmpty { performFuse() }
    }
    
    override func handleLights(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: SignalsDictKey.primed) else { return }
        lightsBuffer = data
        super.handleLights(data)
        fuseTimer?.invalidate()
        if !blipsBuffer.isEmpty { performFuse() }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = blipsBuffer
        for (k, v) in lightsBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        super.handleBlips(combined)
    }
}
