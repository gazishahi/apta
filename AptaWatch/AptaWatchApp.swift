import SwiftUI
import Combine
import WidgetKit

@main
struct AptaWatchApp: App {
    @StateObject private var locationService = WatchLocationService()
    @StateObject private var viewModel = WatchPrayerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _ = WatchSessionDelegate.shared
    }

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
                        locationService.reloadStoredLocation()
                        locationService.start()
                        if let loc = locationService.location {
                            viewModel.calculate(location: loc)
                        } else {
                            viewModel.clearPrayers()
                        }
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
                .onChange(of: locationService.location) { location in
                    guard let loc = location else { viewModel.clearPrayers(); return }
                    viewModel.calculate(location: loc)
                }
                .task(id: viewModel.nextPrayer?.time) {
                    guard let end = viewModel.nextPrayer?.time else { return }
                    do {
                        try await Task.sleep(for: .seconds(max(end.timeIntervalSinceNow, 0)))
                    } catch {
                        return
                    }
                    guard !Task.isCancelled, let location = locationService.location else { return }
                    viewModel.calculate(location: location)
                }
                .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
                    guard let loc = locationService.location else { return }
                    if let next = viewModel.nextPrayer, next.time <= Date() {
                        viewModel.calculate(location: loc)
                    }
                }
                .onChange(of: scenePhase) { phase in
                    guard phase == .active else { return }
                    if let loc = locationService.location {
                        viewModel.calculate(location: loc)
                    }
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
    }
}
