import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: WatchPrayerViewModel
    @ObservedObject var locationService: WatchLocationService

    var body: some View {
        TabView {
            PrayerTimesWatchView(viewModel: viewModel)
            if SharedDefaults.manualLocation == nil {
                QiblaWatchView(viewModel: viewModel, locationService: locationService)
            } else {
                Text("Switch to your current location on iPhone to use Qibla.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .tabViewStyle(.page)
        .environment(\.timeZone, SharedDefaults.prayerTimeZone)
    }
}
