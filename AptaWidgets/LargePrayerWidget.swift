import SwiftUI
import WidgetKit

struct LargePrayerWidgetView: View {
    let entry: PrayerWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if !entry.hasLocation {
            Text("Open apta to set location")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(spacing: 0) {
                Text(entry.hijriDateString.uppercased())
                    .font(.system(size: 12, weight: .regular))
                    .kerning(1.0)
                    .foregroundStyle(tertiaryTextColor)

                Spacer(minLength: 14)

                if let next = entry.nextDailyPrayer {
                    Text(next.name.rawValue.uppercased())
                        .font(.system(size: 30, weight: .medium))
                        .kerning(2.5)
                        .foregroundStyle(textColor)
                        .padding(.top, 2)

                    Text(formatHeroTime(next.time))
                        .font(.system(size: 20, weight: .regular, design: .rounded))
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
                            .frame(width: 220, height: 3)
                            .padding(.top, 10)
                    }

                    Text(next.time, style: .timer)
                        .font(.system(size: 26, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(textColor)
                        .padding(.top, 10)
                }

                Spacer(minLength: 20)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(schedulePrayers) { prayer in
                        VStack(spacing: 3) {
                            Text(prayer.name.rawValue.uppercased())
                                .font(.system(size: 13, weight: prayer.name == .sunrise ? .regular : .medium))
                                .kerning(0.8)
                            Text(formatTime(prayer.time))
                                .font(.system(size: 20, weight: .regular, design: .rounded))
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(prayer.name == .sunrise ? tertiaryTextColor : secondaryTextColor)
                    }
                }
            }
            .multilineTextAlignment(.center)
        }
    }

    private var schedulePrayers: [PrayerTimeEntry] {
        entry.allPrayers.filter { $0.name != .ishraq }
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
        if settings.timeFormat == .twelve {
            formatter.dateFormat = "h:mm"
            let period = Calendar.current.component(.hour, from: date) < 12 ? "A" : "P"
            return "\(formatter.string(from: date)) \(period)"
        }
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatHeroTime(_ date: Date) -> String {
        let settings = PrayerSettings.current
        let formatter = DateFormatter()
        formatter.dateFormat = settings.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }

}
