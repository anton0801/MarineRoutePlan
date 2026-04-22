import SwiftUI
import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {
    private let attributionBridge = AttributionBridge()
    private let pushBridge = PushBridge()
    private var sdkBridge: SDKBridge?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        attributionBridge.onTracking = { [weak self] in self?.relay(tracking: $0) }
        attributionBridge.onNavigation = { [weak self] in self?.relay(navigation: $0) }
        sdkBridge = SDKBridge(bridge: attributionBridge)
        setupFirebase(); setupPush(); setupSDK()
        if let push = launchOptions?[.remoteNotification] as? [AnyHashable: Any] { pushBridge.process(push) }
        observeLifecycle(); return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    private func setupSDK() { sdkBridge?.configure() }
    private func observeLifecycle() { NotificationCenter.default.addObserver(self, selector: #selector(activate), name: UIApplication.didBecomeActiveNotification, object: nil) }
    @objc private func activate() { sdkBridge?.start() }
    

    private func relay(navigation data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: .init("deeplink_values"), object: nil, userInfo: ["deeplinksData": data])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        messaging.token { token, error in
            guard error == nil, let token else { return }
            UserDefaults.standard.set(token, forKey: "fcm_token")
            UserDefaults.standard.set(token, forKey: "push_token")
            UserDefaults(suiteName: "group.marineroute.storage")?.set(token, forKey: "shared_fcm")
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        pushBridge.process(userInfo); completionHandler(.newData)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        pushBridge.process(notification.request.content.userInfo); completionHandler([.banner, .sound, .badge])
    }
    
    private func relay(tracking data: [AnyHashable: Any]) {
        NotificationCenter.default.post(name: .init("ConversionDataReceived"), object: nil, userInfo: ["conversionData": data])
    }
    
    private func setupPush() { Messaging.messaging().delegate = self; UNUserNotificationCenter.current().delegate = self; UIApplication.shared.registerForRemoteNotifications() }
    
    private func setupFirebase() { FirebaseApp.configure() }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        pushBridge.process(response.notification.request.content.userInfo); completionHandler()
    }
    
}

@main
struct MarineRoutePlanApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var applicationDelegate
    
    var body: some Scene {
        WindowGroup {
            LaunchView()
        }
    }
}

struct AppRoot: View {
    
    @StateObject private var appState = AppState()
    
    var body: some View {
        ZStack {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(appState)
                    .transition(.opacity)
            } else if !appState.isLoggedIn {
                AuthView()
                    .environmentObject(appState)
                    .transition(.opacity)
            } else {
                MainTabView()
                    .environmentObject(appState)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.3), value: appState.isLoggedIn)
        .preferredColorScheme(appState.colorScheme)
    }
    
}
