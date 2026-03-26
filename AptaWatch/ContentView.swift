import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: WatchPrayerViewModel
    @ObservedObject var locationService: WatchLocationService

    var body: some View {
        TabView {
            PrayerTimesWatchView(viewModel: viewModel)
            QiblaWatchView(viewModel: viewModel, locationService: locationService)
        }
        .tabViewStyle(.page)
    }
}
