import SwiftUI
import WidgetKit

struct MediumPrayerWidgetView: View {
    let entry: PrayerWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if !entry.hasLocation {
            Text("Open apta to set location")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: 0) {
                if let next = entry.nextDailyPrayer {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(next.name.rawValue.uppercased())
                            .font(.system(size: 22, weight: .medium))
                            .kerning(1.6)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(textColor)

                        Spacer(minLength: 0)

                        Text(formatTime(next.time))
                            .font(.system(size: 22, weight: .regular, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity)

                    if let progressInterval = entry.dailyProgressInterval {
                        ProgressView(timerInterval: progressInterval, countsDown: false) {
                            EmptyView()
                        } currentValueLabel: {
                            EmptyView()
                        }
                            .tint(textColor.opacity(0.62))
                            .frame(maxWidth: .infinity)
                            .frame(height: 3)
                            .padding(.top, 8)
                    }

                    Text(next.time, style: .timer)
                        .font(.system(size: 32, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(textColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)
                }

                Spacer(minLength: 10)

                HStack(spacing: 0) {
                    let others = entry.dailyPrayers.filter { $0.name != entry.nextDailyPrayer?.name }
                    ForEach(Array(others.enumerated()), id: \.element.id) { index, prayer in
                        VStack(spacing: 2) {
                            Text(prayer.name.shortLabel)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(formatTimeShort(prayer.time))
                                .font(.system(size: 17, weight: .regular, design: .rounded))
                                .monospacedDigit()
                        }
                        .multilineTextAlignment(.center)
                        .foregroundStyle(secondaryTextColor)
                        if index < others.count - 1 {
                            Spacer()
                        }
                    }
                }

            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private var textColor: Color {
        let theme = WidgetBackgroundTheme.current
        guard WidgetBackgroundTheme.isProUser, let preset = theme.preset else {
            return Color(uiColor: .label)
        }
        if theme.isAdaptive {
            return colorScheme == .dark ? preset.darkTextColor : preset.lightTextColor
        }
        return theme.preferredVariant == .dark ? preset.darkTextColor : preset.lightTextColor
    }

    private var secondaryTextColor: Color {
        textColor.opacity(0.7)
    }

    private var tertiaryTextColor: Color {
        textColor.opacity(0.5)
    }

    private func formatTime(_ date: Date) -> String {
        let settings = PrayerSettings.current
        let formatter = DateFormatter()
        formatter.dateFormat = settings.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }

    private func formatTimeShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = PrayerSettings.current.timeFormat == .twelve ? "h:mm" : "HH:mm"
        return formatter.string(from: date)
    }

}
