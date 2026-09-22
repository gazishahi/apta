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
        // An empty payload explicitly clears a previous manual selection.
        context[SharedDefaults.manualLocationKey] = suite.data(forKey: SharedDefaults.manualLocationKey) ?? Data()
        context[SharedDefaults.locationUpdatedAtKey] = suite.double(forKey: SharedDefaults.locationUpdatedAtKey)
        context[SharedDefaults.latitudeKey]  = suite.double(forKey: SharedDefaults.latitudeKey)
        context[SharedDefaults.longitudeKey] = suite.double(forKey: SharedDefaults.longitudeKey)
        context[SharedDefaults.isProUserKey] = suite.bool(forKey: SharedDefaults.isProUserKey)
        context[SharedDefaults.proStatusUpdatedAtKey] = suite.double(forKey: SharedDefaults.proStatusUpdatedAtKey)
        if let data = suite.data(forKey: "prayerSettings") {
            context["prayerSettings"] = data
        }
        if let data = suite.data(forKey: SharedDefaults.backgroundThemeKey) {
            context[SharedDefaults.backgroundThemeKey] = data
        }

        try? WCSession.default.updateApplicationContext(context)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(context, replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated {
            sendSettingsUpdate()
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
