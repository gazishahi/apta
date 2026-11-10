import SwiftUI

struct PrayerDayView: View {
    let date: Date
    let isToday: Bool
    @ObservedObject var viewModel: PrayerTimesViewModel
    let settings: PrayerSettings
    let cachedPrayers: [PrayerTimeEntry]
    @Environment(\.colorScheme) private var colorScheme
    @State private var containerSize: CGSize = .zero

    /// Lists stay readable on wide displays such as the inner display of iPhone Duo.
    private let maxListWidth: CGFloat = 480

    /// Wide, landscape space (iPhone Duo open): hero on the left, list on the right.
    private var usesSideBySideLayout: Bool {
        containerSize.width >= 700 && containerSize.width > containerSize.height * 1.2
    }

    var body: some View {
        Group {
            if isToday {
                if usesSideBySideLayout {
                    HStack(spacing: 0) {
                        currentPrayerSection
                            .frame(maxWidth: .infinity)
                        Rectangle()
                            .fill(ThemeColors.quaternaryTextColor(for: colorScheme))
                            .frame(width: 0.5, height: 160)
                        prayerList(viewModel.upcomingPrayers)
                            .frame(maxWidth: maxListWidth)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        currentPrayerSection
                            .padding(.top, -24)

                        Rectangle()
                            .fill(ThemeColors.quaternaryTextColor(for: colorScheme))
                            .frame(width: 40, height: 0.5)
                            .padding(.vertical, 12)

                        prayerList(viewModel.upcomingPrayers)
                            .frame(maxWidth: maxListWidth)
                    }
                }
            } else {
                prayerList(cachedPrayers)
                    .frame(maxWidth: maxListWidth)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            containerSize = size
        }
    }

    @ViewBuilder
    private var currentPrayerSection: some View {
        if let current = viewModel.currentPrayer {
            VStack(spacing: 8) {
                Text(current.name.rawValue.uppercased())
                    .font(Typography.currentPrayerName)
                    .kerning(Typography.currentPrayerNameKerning)
                    .foregroundStyle(ThemeColors.secondaryTextColor(for: colorScheme))

                currentTimeDisplay(for: current.time)

                Text(viewModel.countdown)
                    .font(Typography.countdown)
                    .foregroundStyle(settings.prominentCountdown ? ThemeColors.textColor(for: colorScheme) : ThemeColors.secondaryTextColor(for: colorScheme))
                    .monospacedDigit()

                if let supplementalTime = current.supplementalTime {
                    supplementalTimeText(supplementalTime)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
                }
            }
        }
    }

    private func prayerList(_ prayers: [PrayerTimeEntry]) -> some View {
        VStack(spacing: 0) {
            ForEach(prayers) { prayer in
                HStack {
                    Text(prayer.name.rawValue)
                        .font(Typography.upcomingPrayerName)
                        .foregroundStyle(ThemeColors.textColor(for: colorScheme))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        upcomingTimeDisplay(for: prayer.time)
                        if let supplementalTime = prayer.supplementalTime {
                            supplementalTimeText(supplementalTime)
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(ThemeColors.tertiaryTextColor(for: colorScheme))
                        }
                    }
                }
                .padding(.horizontal, 48)
                .padding(.vertical, 10)
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
        DateFormatterFactory.make(format: settings.timeFormat == .twelve ? "h:mm" : "HH:mm")
    }

    private var amPmFormatter: DateFormatter {
        DateFormatterFactory.make(format: "a")
    }

    private func supplementalTimeText(_ supplementalTime: PrayerSupplementalTime) -> Text {
        Text("\(supplementalTime.label) \(supplementalTimeFormatter.string(from: supplementalTime.time))")
    }

    private var supplementalTimeFormatter: DateFormatter {
        DateFormatterFactory.make(format: settings.timeFormat == .twelve ? "h:mm a" : "HH:mm")
    }
}
