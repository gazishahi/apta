import SwiftUI
import CoreLocation

struct PrayerTimesView: View {
    @ObservedObject var viewModel: PrayerTimesViewModel
    @ObservedObject var locationService: LocationService
    let onOpenSettings: () -> Void

    @State private var qiblaState: QiblaState = .idle
    @State private var lastTickDegree: Int = -999
    @State private var smoothedHeading: Double = 0

    enum QiblaState: Equatable {
        case idle
        case searching
        case found
    }

    private var settings: PrayerSettings { PrayerSettings.current }

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = settings.timeFormat == .twelve ? "h:mm" : "HH:mm"
        return f
    }

    private var amPmFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "a"
        return f
    }

    private let qiblaThreshold: Double = 10.0

    private var qiblaOffset: Double? {
        guard let heading = locationService.heading else { return nil }
        var diff = viewModel.qiblaDirection - heading
        // Normalize to -180...180
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }

    var body: some View {
        ZStack {
            AptaColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    if !locationService.locationName.isEmpty {
                        Text(locationService.locationName.uppercased())
                            .font(.system(size: 11, weight: .medium))
                            .kerning(1.5)
                            .foregroundStyle(AptaColors.tertiary)
                    }
                    Spacer()
                    Button {
                        Haptics.light()
                        onOpenSettings()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(AptaColors.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Hijri date
                if !viewModel.hijriDateString.isEmpty {
                    Text(viewModel.hijriDateString)
                        .font(.system(size: 13, weight: .regular))
                        .textCase(.uppercase)
                        .foregroundStyle(AptaColors.tertiary)
                        .padding(.bottom, 20)
                }

                // Current prayer
                if let current = viewModel.currentPrayer {
                    VStack(spacing: 8) {
                        Text(current.name.rawValue.uppercased())
                            .font(Typography.currentPrayerName)
                            .kerning(Typography.currentPrayerNameKerning)
                            .foregroundStyle(AptaColors.secondary)

                        currentTimeDisplay(for: current.time)

                        Text(viewModel.countdown)
                            .font(Typography.countdown)
                            .foregroundStyle(AptaColors.tertiary)
                    }
                    .transition(.opacity)
                }

                // Divider
                Rectangle()
                    .fill(AptaColors.separator)
                    .frame(width: 40, height: 0.5)
                    .padding(.vertical, 32)

                // Upcoming prayers
                VStack(spacing: 0) {
                    ForEach(viewModel.upcomingPrayers) { prayer in
                        HStack {
                            Text(prayer.name.rawValue)
                                .font(Typography.upcomingPrayerName)
                                .foregroundStyle(AptaColors.primary)
                            Spacer()
                            upcomingTimeDisplay(for: prayer.time)
                        }
                        .padding(.horizontal, 48)
                        .padding(.vertical, 10)
                    }
                }

                Spacer()

                // Qibla
                qiblaView
                    .padding(.bottom, 24)
            }
        }
        .animation(AnimationConstants.prayerTransition, value: viewModel.currentPrayer?.name)
        .onChange(of: locationService.heading) {
            if let newHeading = locationService.heading {
                // Shortest-path interpolation across 0°/360° boundary
                var delta = newHeading - smoothedHeading
                while delta > 180 { delta -= 360 }
                while delta < -180 { delta += 360 }
                withAnimation(.easeOut(duration: 0.15)) {
                    smoothedHeading += delta
                }
            }
            guard qiblaState == .searching, let offset = qiblaOffset else { return }
            if abs(offset) <= qiblaThreshold {
                Haptics.qiblaFound()
                withAnimation(AnimationConstants.prayerTransition) {
                    qiblaState = .found
                }
                locationService.stopHeadingUpdates()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(AnimationConstants.prayerTransition) {
                        qiblaState = .idle
                    }
                }
            } else {
                // Tick every 5 degrees of rotation
                let currentDegree = Int(offset) / 5
                if currentDegree != lastTickDegree {
                    lastTickDegree = currentDegree
                    Haptics.qiblaTick()
                }
            }
        }
        .onChange(of: viewModel.currentPrayer?.name) {
            Haptics.soft()
        }
    }

    @ViewBuilder
    private var qiblaView: some View {
        VStack(spacing: 0) {
            // Compass strip overlays above the button without shifting layout
            ZStack {
                if qiblaState == .searching, locationService.heading != nil {
                    QiblaStripCompass(
                        heading: smoothedHeading,
                        qiblaDirection: viewModel.qiblaDirection
                    )
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .bottom)))
                }
            }
            .frame(height: qiblaState == .searching ? 44 : 0)
            .clipped()
            .padding(.bottom, qiblaState == .searching ? 8 : 0)

            Button {
                switch qiblaState {
                case .idle:
                    Haptics.light()
                    lastTickDegree = -999
                    withAnimation(.easeInOut(duration: 0.35)) {
                        qiblaState = .searching
                    }
                    locationService.startHeadingUpdates()
                case .searching:
                    Haptics.light()
                    withAnimation(.easeInOut(duration: 0.35)) {
                        qiblaState = .idle
                    }
                    locationService.stopHeadingUpdates()
                case .found:
                    break
                }
            } label: {
                HStack {
                    Spacer()

                    switch qiblaState {
                    case .idle:
                        Text("QIBLA")
                            .font(.system(size: 13, weight: .medium))
                            .kerning(2.0)
                            .foregroundStyle(AptaColors.tertiary)
                    case .searching:
                        if let offset = qiblaOffset {
                            Text(abs(offset) <= qiblaThreshold ? "FOUND" : "QIBLA")
                                .font(.system(size: 13, weight: .medium))
                                .kerning(2.0)
                                .foregroundStyle(abs(offset) <= qiblaThreshold ? AptaColors.primary : AptaColors.tertiary)
                        } else {
                            Text("SEARCHING")
                                .font(.system(size: 13, weight: .medium))
                                .kerning(2.0)
                                .foregroundStyle(AptaColors.tertiary)
                        }
                    case .found:
                        Text("FOUND")
                            .font(.system(size: 13, weight: .medium))
                            .kerning(2.0)
                            .foregroundStyle(AptaColors.primary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .disabled(qiblaState == .found)
        }
    }

    @ViewBuilder
    private func currentTimeDisplay(for date: Date) -> some View {
        if settings.timeFormat == .twelve {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(timeFormatter.string(from: date))
                    .font(Typography.currentTime)
                    .kerning(Typography.currentTimeKerning)
                    .foregroundStyle(AptaColors.primary)
                    .monospacedDigit()
                Text(amPmFormatter.string(from: date))
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(AptaColors.tertiary)
            }
        } else {
            Text(timeFormatter.string(from: date))
                .font(Typography.currentTime)
                .kerning(Typography.currentTimeKerning)
                .foregroundStyle(AptaColors.primary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func upcomingTimeDisplay(for date: Date) -> some View {
        if settings.timeFormat == .twelve {
            HStack(spacing: 3) {
                Text(timeFormatter.string(from: date))
                    .font(Typography.upcomingPrayerTime)
                    .foregroundStyle(AptaColors.secondary)
                Text(amPmFormatter.string(from: date))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(AptaColors.tertiary)
            }
        } else {
            Text(timeFormatter.string(from: date))
                .font(Typography.upcomingPrayerTime)
                .foregroundStyle(AptaColors.secondary)
        }
    }
}
