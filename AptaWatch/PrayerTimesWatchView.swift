import SwiftUI

struct PrayerTimesWatchView: View {
    @ObservedObject var viewModel: WatchPrayerViewModel
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    var body: some View {
        ZStack {
            WatchThemeColors.backgroundColor(isProUser: viewModel.isProUser, preset: viewModel.backgroundPreset)
                .ignoresSafeArea()

            if let next = viewModel.nextPrayer {
                VStack(spacing: 0) {
                    // Hijri date
                    if !viewModel.hijriDate.isEmpty {
                        Text(viewModel.hijriDate.uppercased())
                            .font(.system(size: 9, weight: .light))
                            .tracking(1.5)
                            .foregroundColor(WatchThemeColors.secondaryTextColor())
                            .padding(.bottom, 5)
                    }

                    // Hero: next prayer name + countdown
                    VStack(spacing: 1) {
                        Text(next.name.rawValue.uppercased())
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(WatchThemeColors.textColor())

                        // The system owns both countdowns, including Always On.
                        if isLuminanceReduced {
                            PrayerCountdownText(start: viewModel.countdownStart, end: viewModel.countdownEnd(for: next))
                                .font(.system(size: 18, weight: .thin, design: .monospaced))
                                .foregroundColor(WatchThemeColors.textColor())
                                .monospacedDigit()
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        } else {
                            PrayerCountdownText(start: viewModel.countdownStart, end: viewModel.countdownEnd(for: next), minutesOnly: false)
                                .font(.system(size: 18, weight: .thin, design: .monospaced))
                                .foregroundColor(WatchThemeColors.textColor())
                                .monospacedDigit()
                        }
                    }
                    .padding(.bottom, 7)

                    // Short rule — separates hero from list without dominating
                    Rectangle()
                        .frame(width: 36, height: 0.5)
                        .foregroundColor(WatchThemeColors.tertiaryTextColor().opacity(0.5))
                        .padding(.bottom, 7)

                    // Remaining upcoming prayers (forward-looking only)
                    VStack(spacing: 4) {
                        ForEach(Array(viewModel.upcomingPrayers.enumerated()), id: \.element.id) { index, prayer in
                            if index == viewModel.tomorrowStartIndex {
                                Text("TOMORROW")
                                    .font(.system(size: 8, weight: .medium))
                                    .tracking(1.5)
                                    .foregroundColor(WatchThemeColors.tertiaryTextColor())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, index == 0 ? 0 : 2)
                            }
                            HStack {
                                Text(prayer.name.rawValue)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(WatchThemeColors.secondaryTextColor())
                                Spacer()
                                Text(prayer.time, style: .time)
                                    .font(.system(size: 11, weight: .light, design: .monospaced))
                                    .foregroundColor(WatchThemeColors.secondaryTextColor())
                                    .monospacedDigit()
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
            } else {
                Text("No prayer data")
                    .font(.system(size: 13))
                    .foregroundColor(WatchThemeColors.secondaryTextColor())
            }
        }
    }

}
