import BackgroundTasks
import OSLog
import UIKit

@MainActor
final class NotificationAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        NotificationBackgroundRefresh.register()
        return true
    }
}

@MainActor
enum NotificationBackgroundRefresh {
    static let identifier = "Gazi.apta.refreshPrayerNotifications"
    private static let logger = Logger(subsystem: "Gazi.apta", category: "NotificationRefresh")
    private static var registered = false

    static func register() {
        guard !registered else { return }
        registered = BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: .main) { task in
            let work = Task { @MainActor in
                // This uses the persisted manual/cached location, never GPS.
                let update = NotificationScheduler.scheduleUpcoming(location: NotificationScheduler.savedLocation())
                let success = await withTaskCancellationHandler {
                    await update.value
                } onCancel: {
                    update.cancel()
                }
                task.setTaskCompleted(success: success && !Task.isCancelled)
            }
            task.expirationHandler = { work.cancel() }
        }
        if !registered { logger.error("Failed to register notification background refresh") }
    }

    static func scheduleNext() {
        Task { @MainActor in
            let pending = await BGTaskScheduler.shared.pendingTaskRequests()
            let settings = PrayerSettings.current
            guard settings.notificationsEnabled, PrayerNotificationPlan.hasEnabledAlerts(settings) else {
                BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
                return
            }
            let earliest = Date().addingTimeInterval(6 * 3600)
            // Opening the app repeatedly must not keep postponing an earlier request.
            if pending.contains(where: { $0.identifier == identifier && ($0.earliestBeginDate ?? .distantPast) <= earliest }) {
                return
            }
            let request = BGAppRefreshTaskRequest(identifier: identifier)
            request.earliestBeginDate = earliest
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                logger.error("Could not schedule notification refresh: \(String(describing: error), privacy: .public)")
            }
        }
    }
}
