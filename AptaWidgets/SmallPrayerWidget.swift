import SwiftUI
import WidgetKit

struct SmallPrayerWidgetView: View {
    let entry: PrayerWidgetEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if !entry.hasLocation {
            Text("Open apta to set location")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(displayedPrayers.enumerated()), id: \.element.id) { index, prayer in
                    let isNext = prayer.name == entry.nextPrayer
                    let isCurrent = prayer.name == entry.currentPrayer
                    if index > 0 {
                        Spacer(minLength: 4)
                    }
                    HStack(spacing: 0) {
                        Text(isNext ? ">" : " ")
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 11, alignment: .leading)
                        Text(prayer.name.rawValue.uppercased())
                            .font(.system(size: 14, weight: .regular))
                            .kerning(1.5)
                            .underline(isCurrent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 4)
                        Text(formatTime(prayer.time))
                            .font(.system(size: 14, weight: .regular))
                            .monospacedDigit()
                            .underline(isCurrent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(rowColor(isNext: isNext, isCurrent: isCurrent))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var displayedPrayers: [PrayerTimeEntry] {
        var prayers = entry.allPrayers
        if let currentPrayer = entry.currentPrayer,
           let previousPrayerTime = entry.previousPrayerTime,
           !prayers.contains(where: { $0.name == currentPrayer }) {
            prayers.insert(PrayerTimeEntry(name: currentPrayer, time: previousPrayerTime), at: 0)
        }
        return Array(prayers.prefix(entry.allPrayers.count))
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

    private var tertiaryTextColor: Color {
        textColor.opacity(0.5)
    }

    private var secondaryTextColor: Color {
        textColor.opacity(0.7)
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
        if settings.timeFormat == .twelve {
            formatter.dateFormat = "h:mm"
            let time = formatter.string(from: date)
            let period = Calendar.current.component(.hour, from: date) < 12 ? "A" : "P"
            return "\(time) \(period)"
        } else {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
    }
}
