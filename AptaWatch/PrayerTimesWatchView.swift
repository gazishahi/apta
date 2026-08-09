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

                        // Always-On disallows per-second updates, making style .timer
                        // fall back to verbose text that overflows — show a compact
                        // minute-level countdown there instead.
                        if isLuminanceReduced {
                            TimelineView(.everyMinute) { context in
                                Text(compactRemaining(until: next.time, from: context.date))
                                    .font(.system(size: 18, weight: .thin, design: .monospaced))
                                    .foregroundColor(WatchThemeColors.textColor())
                                    .monospacedDigit()
                            }
                        } else {
                            Text(next.time, style: .timer)
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
                        ForEach(viewModel.upcomingPrayers) { prayer in
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

    private func compactRemaining(until end: Date, from now: Date) -> String {
        let minutes = max(Int(end.timeIntervalSince(now) / 60), 0)
        if minutes >= 60 {
            return "\(minutes / 60)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }
}
