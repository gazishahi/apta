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
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.hijriDateString)
                    .font(.system(size: 11, weight: .regular))
                    .kerning(1.0)
                    .foregroundStyle(tertiaryTextColor)

                if let next = entry.nextPrayer, let time = entry.nextPrayerTime {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(next.rawValue.uppercased())
                            .font(.system(size: 20, weight: .medium))
                            .kerning(3.0)
                            .foregroundStyle(textColor)

                        HStack(alignment: .firstTextBaseline) {
                            Text(formatTime(time))
                                .font(.system(size: 15, weight: .regular))
                                .foregroundStyle(secondaryTextColor)
                            Spacer()
                            Text(countdown(to: time))
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(secondaryTextColor)
                        }
                    }
                }

                Spacer(minLength: 2)

                HStack(spacing: 0) {
                    let others = entry.allPrayers.filter { $0.name != entry.nextPrayer }
                    ForEach(Array(others.enumerated()), id: \.element.id) { index, prayer in
                        VStack(spacing: 1) {
                            Text(prayer.name.rawValue)
                                .font(.system(size: 12, weight: .regular))
                            Text(formatTimeShort(prayer.time))
                                .font(.system(size: 12, weight: .light))
                        }
                        .foregroundStyle(tertiaryTextColor)
                        if index < others.count - 1 {
                            Spacer()
                        }
                    }
                }
            }
            .padding(2)
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

    private func countdown(to date: Date) -> String {
        let diff = date.timeIntervalSince(entry.date)
        guard diff > 0 else { return "now" }
        let h = Int(diff) / 3600
        let m = (Int(diff) % 3600) / 60
        if h > 0 { return "in \(h)h \(m)m" }
        return "in \(m)m"
    }
}
