import Foundation
import WatchConnectivity

final class WatchSyncService: NSObject, WCSessionDelegate {
    static let shared = WatchSyncService()

    private override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func sendSettingsUpdate() {
        guard WCSession.isSupported(),
              WCSession.default.activationState == .activated else { return }

        let suite = SharedDefaults.suite
        var context: [String: Any] = ["action": "refresh"]
        context[SharedDefaults.latitudeKey]  = suite.double(forKey: SharedDefaults.latitudeKey)
        context[SharedDefaults.longitudeKey] = suite.double(forKey: SharedDefaults.longitudeKey)
        context[SharedDefaults.isProUserKey] = suite.bool(forKey: SharedDefaults.isProUserKey)
        if let data = suite.data(forKey: "prayerSettings") {
            context["prayerSettings"] = data
        }
        if let data = suite.data(forKey: SharedDefaults.backgroundThemeKey) {
            context[SharedDefaults.backgroundThemeKey] = data
        }

        try? WCSession.default.updateApplicationContext(context)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
