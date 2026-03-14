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
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.hijriDateString)
                    .font(.system(size: 12, weight: .regular))
                    .kerning(1.5)
                    .foregroundStyle(tertiaryTextColor)

                Spacer()

                if let next = entry.nextPrayer, let time = entry.nextPrayerTime {
                    Text(next.rawValue.uppercased())
                        .font(.system(size: 28, weight: .medium))
                        .kerning(5.0)
                        .foregroundStyle(textColor)

                    Spacer().frame(height: 6)

                    HStack(alignment: .firstTextBaseline) {
                        Text(formatTime(time))
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(secondaryTextColor)
                        Spacer()
                        Text(countdown(to: time))
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(secondaryTextColor)
                    }
                }

                Spacer()

                Divider()

                Spacer().frame(height: 16)

                ForEach(entry.allPrayers) { prayer in
                    let isNext = prayer.name == entry.nextPrayer
                    HStack(spacing: 0) {
                        Text(isNext ? ">" : " ")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 14, alignment: .leading)
                        Text(prayer.name.rawValue)
                            .font(.system(size: 16, weight: isNext ? .medium : .regular))
                        Spacer()
                        Text(formatTime(prayer.time))
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundStyle(isNext ? textColor : tertiaryTextColor)

                    if prayer.name != entry.allPrayers.last?.name {
                        Spacer()
                    }
                }
            }
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

    private func countdown(to date: Date) -> String {
        let diff = date.timeIntervalSince(entry.date)
        guard diff > 0 else { return "now" }
        let h = Int(diff) / 3600
        let m = (Int(diff) % 3600) / 60
        if h > 0 { return "in \(h)h \(m)m" }
        return "in \(m)m"
    }
}
