import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AttributionBridge: NSObject {
    var onTracking: (([AnyHashable: Any]) -> Void)?
    var onNavigation: (([AnyHashable: Any]) -> Void)?
    private var trackingBuf: [AnyHashable: Any] = [:], navigationBuf: [AnyHashable: Any] = [:], timer: Timer?
    
    func receiveTracking(_ data: [AnyHashable: Any]) { trackingBuf = data; scheduleTimer(); if !navigationBuf.isEmpty { merge() } }
    func receiveNavigation(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: "mrp_first_launch_flag") else { return }
        navigationBuf = data; onNavigation?(data); timer?.invalidate(); if !trackingBuf.isEmpty { merge() }
    }
    private func scheduleTimer() { timer?.invalidate(); timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in self?.merge() } }
    private func merge() { var result = trackingBuf; navigationBuf.forEach { k, v in let key = "deep_\(k)"; if result[key] == nil { result[key] = v } }; onTracking?(result) }
}


final class SDKBridge: NSObject, AppsFlyerLibDelegate, DeepLinkDelegate {
    private var bridge: AttributionBridge
    init(bridge: AttributionBridge) { self.bridge = bridge }
    func configure() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = MarineRouteConfig.devKey; sdk.appleAppID = MarineRouteConfig.appID
        sdk.delegate = self; sdk.deepLinkDelegate = self; sdk.isDebug = false
    }
    func start() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in DispatchQueue.main.async { AppsFlyerLib.shared().start(); UserDefaults.standard.set(status.rawValue, forKey: "att_status") } }
        } else { AppsFlyerLib.shared().start() }
    }
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) { bridge.receiveTracking(data) }
    func onConversionDataFail(_ error: Error) { bridge.receiveTracking(["error": true, "error_desc": error.localizedDescription]) }
    func didResolveDeepLink(_ result: DeepLinkResult) { guard case .found = result.status, let dl = result.deepLink else { return }; bridge.receiveNavigation(dl.clickEvent) }
}
