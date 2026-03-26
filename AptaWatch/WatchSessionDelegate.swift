import Foundation
import Combine
import WatchConnectivity

final class WatchSessionDelegate: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionDelegate()
    var onRefresh: (() -> Void)?

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard message["action"] as? String == "refresh" else { return }
        storePayload(message)
        DispatchQueue.main.async { self.onRefresh?() }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard applicationContext["action"] as? String == "refresh" else { return }
        storePayload(applicationContext)
        DispatchQueue.main.async { self.onRefresh?() }
    }

    private func storePayload(_ payload: [String: Any]) {
        let suite = SharedDefaults.suite
        if let lat = payload[SharedDefaults.latitudeKey] as? Double { suite.set(lat, forKey: SharedDefaults.latitudeKey) }
        if let lon = payload[SharedDefaults.longitudeKey] as? Double { suite.set(lon, forKey: SharedDefaults.longitudeKey) }
        if let isPro = payload[SharedDefaults.isProUserKey] as? Bool { suite.set(isPro, forKey: SharedDefaults.isProUserKey) }
        if let data = payload["prayerSettings"] as? Data { suite.set(data, forKey: "prayerSettings") }
        if let data = payload[SharedDefaults.backgroundThemeKey] as? Data { suite.set(data, forKey: SharedDefaults.backgroundThemeKey) }
    }
}
