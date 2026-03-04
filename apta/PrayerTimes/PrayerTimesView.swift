import SwiftUI
import CoreLocation

struct PrayerTimesView: View {
    @ObservedObject var viewModel: PrayerTimesViewModel
    @ObservedObject var locationService: LocationService
    let onOpenSettings: () -> Void

    @State private var qiblaState: QiblaState = .idle
    @State private var lastTickDegree: Int = -999

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
        .animation(AnimationConstants.prayerTransition, value: qiblaState)
        .onChange(of: locationService.heading) {
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
        Button {
            switch qiblaState {
            case .idle:
                Haptics.light()
                lastTickDegree = -999
                withAnimation(AnimationConstants.prayerTransition) {
                    qiblaState = .searching
                }
                locationService.startHeadingUpdates()
            case .searching:
                Haptics.light()
                withAnimation(AnimationConstants.prayerTransition) {
                    qiblaState = .idle
                }
                locationService.stopHeadingUpdates()
            case .found:
                break
            }
        } label: {
            HStack {
                if qiblaState == .searching, let offset = qiblaOffset, offset < -qiblaThreshold {
                    Text("<")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AptaColors.primary)
                        .transition(.opacity)
                }

                Spacer()

                switch qiblaState {
                case .idle:
                    Text("QIBLA")
                        .font(.system(size: 13, weight: .medium))
                        .kerning(2.0)
                        .foregroundStyle(AptaColors.tertiary)
                case .searching:
                    if let offset = qiblaOffset {
                        Text(abs(offset) <= qiblaThreshold ? "FOUND" : (offset > 0 ? "RIGHT" : "LEFT"))
                            .font(.system(size: 13, weight: .medium))
                            .kerning(2.0)
                            .foregroundStyle(AptaColors.primary)
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

                if qiblaState == .searching, let offset = qiblaOffset, offset > qiblaThreshold {
                    Text(">")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AptaColors.primary)
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 24)
        }
        .disabled(qiblaState == .found)
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
