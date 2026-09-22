import SwiftUI
import CoreLocation
import WidgetKit

@main
struct aptaApp: App {
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
            }
        }
    }

    private func rescheduleNotifications() {
        let defaults = SharedDefaults.suite
        let lat = defaults.double(forKey: SharedDefaults.latitudeKey)
        let lon = defaults.double(forKey: SharedDefaults.longitudeKey)
        guard lat != 0 || lon != 0 else { return }
        let location = CLLocation(latitude: lat, longitude: lon)
        NotificationScheduler.scheduleUpcoming(location: location)
    }
}
