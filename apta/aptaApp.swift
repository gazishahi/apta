import SwiftUI
import CoreLocation

@main
struct aptaApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootCoordinator()
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                rescheduleNotifications()
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
