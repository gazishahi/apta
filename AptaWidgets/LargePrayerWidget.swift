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
                    Text("NEXT")
                        .font(.system(size: 11, weight: .semibold))
                        .kerning(1.8)
                        .foregroundStyle(tertiaryTextColor)

                    Spacer().frame(height: 6)

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
                        Text(time, style: .relative)
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(secondaryTextColor)
                    }
                }

                Spacer()

                Divider()

                Spacer().frame(height: 16)

                ForEach(displayedPrayers) { prayer in
                    let isNext = prayer.name == entry.nextPrayer
                    let isCurrent = prayer.name == entry.currentPrayer
                    HStack(spacing: 0) {
                        Text(prayer.name.rawValue)
                            .font(.system(size: 16, weight: isNext ? .medium : .regular))
                            .underline(isCurrent)
                        Spacer()
                        Text(formatTime(prayer.time))
                            .font(.system(size: 16, weight: .regular))
                            .underline(isCurrent)
                    }
                    .foregroundStyle(rowColor(isNext: isNext, isCurrent: isCurrent))

                    if prayer.id != displayedPrayers.last?.id {
                        Spacer()
                    }
                }
            }
        }
    }

    private var displayedPrayers: [PrayerTimeEntry] {
        var prayers = entry.allPrayers
        if let currentPrayer = entry.currentPrayer,
           let previousPrayerTime = entry.previousPrayerTime,
           !prayers.contains(where: { $0.name == currentPrayer }) {
            prayers.insert(PrayerTimeEntry(name: currentPrayer, time: previousPrayerTime), at: 0)
        }
        return prayers
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

    private func rowColor(isNext: Bool, isCurrent: Bool) -> Color {
        if isNext {
            return textColor
        }
        if isCurrent {
            return secondaryTextColor
        }
        return tertiaryTextColor
    }

    private func formatTime(_ date: Date) -> String {
        let settings = PrayerSettings.current
        let formatter = DateFormatter()
        formatter.dateFormat = settings.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }

}
