import SwiftUI
import WidgetKit

// Small hero widget: just the next prayer, as large as the space allows.
struct NextPrayerWidgetView: View {
    let entry: PrayerWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if !entry.hasLocation {
            Text("Open apta to set location")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if let next = entry.nextDailyPrayer {
            VStack(spacing: 0) {
                Text(next.name.rawValue.uppercased())
                    .font(.system(size: 26, weight: .medium))
                    .kerning(2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(textColor)

                Text(formatTime(next.time))
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(secondaryTextColor)
                    .padding(.top, 2)

                if let progressInterval = entry.dailyProgressInterval {
                    ProgressView(timerInterval: progressInterval, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                        .tint(textColor.opacity(0.62))
                        .frame(maxWidth: .infinity)
                        .frame(height: 3)
                        .padding(.top, 10)
                }

                Text(next.time, style: .timer)
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(textColor)
                    .padding(.top, 8)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("Open apta").font(.caption)
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

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = PrayerSettings.current.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }
}

struct NextPrayerWidget: Widget {
    let kind = "NextPrayerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimelineProvider()) { entry in
            NextPrayerWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetContainerBackground()
                }
        }
        .configurationDisplayName("Next Prayer")
        .description("The next prayer with a live countdown.")
        .supportedFamilies([.systemSmall])
    }
}
