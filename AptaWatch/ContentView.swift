import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: WatchPrayerViewModel
    @ObservedObject var locationService: WatchLocationService
    @State private var page = ContentView.initialPage

    var body: some View {
        TabView(selection: $page) {
            PrayerTimesWatchView(viewModel: viewModel)
                .tag(0)
            if SharedDefaults.manualLocation == nil {
                QiblaWatchView(viewModel: viewModel, locationService: locationService)
                    .tag(1)
            } else {
                Text("Switch to your current location on iPhone to use Qibla.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding()
                    .tag(1)
            }
        }
        .tabViewStyle(.page)
        .environment(\.timeZone, SharedDefaults.prayerTimeZone)
    }

    private static var initialPage: Int {
        #if DEBUG
        if CaptureMode.screen == .qibla { return 1 }
        #endif
        return 0
    }
}
