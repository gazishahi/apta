import SwiftUI
import CoreLocation
import WidgetKit

@main
struct aptaApp: App {
    @UIApplicationDelegateAdaptor(NotificationAppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var purchaseManager = PurchaseManager.shared
    @StateObject private var locationService = LocationService()

    var body: some Scene {
        WindowGroup {
            RootCoordinator(locationService: locationService)
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                rescheduleNotifications()
                WidgetCenter.shared.reloadAllTimelines()
                Task { _ = await purchaseManager.refreshEntitlements() }
            } else if scenePhase == .background {
                NotificationBackgroundRefresh.scheduleNext()
            }
        }
    }

    private func rescheduleNotifications() {
        NotificationScheduler.scheduleUpcoming(location: NotificationScheduler.savedLocation())
    }
}
