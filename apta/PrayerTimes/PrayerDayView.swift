import SwiftUI

struct PrayerDayView: View {
    let date: Date
    let isToday: Bool
    @ObservedObject var viewModel: PrayerTimesViewModel
    let settings: PrayerSettings
    let cachedPrayers: [PrayerTimeEntry]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if isToday {
                VStack(spacing: 0) {
                    if let current = viewModel.currentPrayer {
                        VStack(spacing: 8) {
                            Text(current.name.rawValue.uppercased())
                                .font(Typography.currentPrayerName)
                                .kerning(Typography.currentPrayerNameKerning)
                                .foregroundStyle(ThemeColors.secondaryTextColor(for: colorScheme))

                            currentTimeDisplay(for: current.time)

                            Text(viewModel.countdown)
                                .font(Typography.countdown)
                                .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
                        }
                        .padding(.top, -24)
                    }

                    Rectangle()
                        .fill(ThemeColors.quaternaryTextColor(for: colorScheme))
                        .frame(width: 40, height: 0.5)
                        .padding(.vertical, 12)

                    VStack(spacing: 0) {
                        ForEach(viewModel.upcomingPrayers) { prayer in
                            HStack {
                                Text(prayer.name.rawValue)
                                    .font(Typography.upcomingPrayerName)
                                    .foregroundStyle(ThemeColors.textColor(for: colorScheme))
                                Spacer()
                                upcomingTimeDisplay(for: prayer.time)
                            }
                            .padding(.horizontal, 48)
                            .padding(.vertical, 10)
                        }
                    }
                }
            } else {
                VStack(spacing: 0) {
                    ForEach(cachedPrayers) { prayer in
                        HStack {
                            Text(prayer.name.rawValue)
                                .font(Typography.upcomingPrayerName)
                                .foregroundStyle(ThemeColors.textColor(for: colorScheme))
                            Spacer()
                            upcomingTimeDisplay(for: prayer.time)
                        }
                        .padding(.horizontal, 48)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func currentTimeDisplay(for date: Date) -> some View {
        if settings.timeFormat == .twelve {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(timeFormatter.string(from: date))
                    .font(Typography.currentTime)
                    .kerning(Typography.currentTimeKerning)
                    .foregroundStyle(ThemeColors.textColor(for: colorScheme))
                    .monospacedDigit()
                Text(amPmFormatter.string(from: date))
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
            }
        } else {
            Text(timeFormatter.string(from: date))
                .font(Typography.currentTime)
                .kerning(Typography.currentTimeKerning)
                .foregroundStyle(ThemeColors.textColor(for: colorScheme))
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func upcomingTimeDisplay(for date: Date) -> some View {
        if settings.timeFormat == .twelve {
            HStack(spacing: 3) {
                Text(timeFormatter.string(from: date))
                    .font(Typography.upcomingPrayerTime)
                    .foregroundStyle(ThemeColors.secondaryTextColor(for: colorScheme))
                Text(amPmFormatter.string(from: date))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
            }
        } else {
            Text(timeFormatter.string(from: date))
                .font(Typography.upcomingPrayerTime)
                .foregroundStyle(ThemeColors.secondaryTextColor(for: colorScheme))
        }
    }

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
}
