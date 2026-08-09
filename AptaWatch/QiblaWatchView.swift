import SwiftUI
import WatchKit

struct QiblaWatchView: View {
    @ObservedObject var viewModel: WatchPrayerViewModel
    @ObservedObject var locationService: WatchLocationService

    @State private var isAligned = false
    @State private var lastTickDegree: Int = Int.min

    private let qiblaThreshold: Double = 5.0

    private var offset: Double {
        var diff = viewModel.qiblaDirection - locationService.heading
        while diff > 180  { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    var body: some View {
        ZStack {
            WatchThemeColors.backgroundColor(isProUser: viewModel.isProUser, preset: viewModel.backgroundPreset)
                .ignoresSafeArea()

            if viewModel.isProUser {
                proContent
            } else {
                lockedContent
            }
        }
        .onAppear {
            SharedDefaults.suite.synchronize()
            locationService.startHeading()
        }
        .onDisappear { locationService.stopHeading() }
        .onChange(of: locationService.heading) { _ in
            updateAlignment()
        }
    }

    private var proContent: some View {
        // Dial fills the screen; label and degree readout sit in its empty center.
        ZStack {
            WatchQiblaCompass(
                heading: locationService.heading,
                qiblaDirection: viewModel.qiblaDirection
            )

            VStack(spacing: 2) {
                Text(isAligned ? "FOUND" : "QIBLA")
                    .font(.system(size: 11, weight: isAligned ? .semibold : .light))
                    .tracking(2)
                    .foregroundColor(isAligned ? WatchThemeColors.textColor() : WatchThemeColors.secondaryTextColor())
                    .animation(.easeInOut(duration: 0.2), value: isAligned)

                Text(String(format: "%.0f°", abs(offset)))
                    .font(.system(size: 18, weight: .thin, design: .monospaced))
                    .foregroundColor(WatchThemeColors.textColor())
                    .monospacedDigit()
            }
        }
        .padding(4)
    }

    private var lockedContent: some View {
        VStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 20))
                .foregroundColor(WatchThemeColors.secondaryTextColor())

            Text("apta Pro")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(WatchThemeColors.textColor())

            Text("Unlock Qibla\non Apple Watch")
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .foregroundColor(WatchThemeColors.secondaryTextColor())
        }
        .padding()
    }

    private func updateAlignment() {
        let nowAligned = abs(offset) <= qiblaThreshold

        if nowAligned && !isAligned {
            // Just found Qibla — success bump then heavy pulse
            WKInterfaceDevice.current().play(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                WKInterfaceDevice.current().play(.notification)
            }
        } else if !nowAligned {
            // Tick every 5° step while searching
            let step = Int(offset) / 5
            if step != lastTickDegree {
                lastTickDegree = step
                WKInterfaceDevice.current().play(.click)
            }
        }

        isAligned = nowAligned
    }
}
