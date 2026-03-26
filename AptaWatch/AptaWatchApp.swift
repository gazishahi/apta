import SwiftUI
import Combine
import WidgetKit

@main
struct AptaWatchApp: App {
    @StateObject private var locationService = WatchLocationService()
    @StateObject private var viewModel = WatchPrayerViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel, locationService: locationService)
                .onAppear {
                    locationService.start()
                    SharedDefaults.suite.synchronize()
                    if let loc = locationService.location {
                        viewModel.calculate(location: loc)
                    }
                    // Refresh on WatchConnectivity signal — data is already written to SharedDefaults by the delegate
                    WatchSessionDelegate.shared.onRefresh = { [self] in
                        // If watch has no GPS fix, load the location the iPhone just sent
                        if locationService.location == nil {
                            locationService.reloadStoredLocation()
                        }
                        if let loc = locationService.location {
                            viewModel.calculate(location: loc)
                        }
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
                .onChange(of: locationService.location) { location in
                    guard let loc = location else { return }
                    viewModel.calculate(location: loc)
                }
                .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                    guard let loc = locationService.location else { return }
                    if let next = viewModel.nextPrayer, next.time <= Date() {
                        viewModel.calculate(location: loc)
                    }
                }
        }
    }
}
