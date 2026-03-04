import SwiftUI
import WidgetKit

struct LargePrayerWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        if !entry.hasLocation {
            Text("Open apta to set location")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                // Header: Hijri date
                Text(entry.hijriDateString)
                    .font(.system(size: 12, weight: .regular))
                    .kerning(1.5)
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))

                Spacer()

                // Next prayer prominent
                if let next = entry.nextPrayer, let time = entry.nextPrayerTime {
                    Text(next.rawValue.uppercased())
                        .font(.system(size: 28, weight: .medium))
                        .kerning(5.0)
                        .foregroundStyle(Color(uiColor: .label))

                    Spacer().frame(height: 6)

                    HStack(alignment: .firstTextBaseline) {
                        Text(formatTime(time))
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                        Spacer()
                        Text(countdown(to: time))
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }

                Spacer()

                Divider()

                Spacer().frame(height: 16)

                // Full prayer list with generous spacing
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
                    .foregroundStyle(isNext ? Color(uiColor: .label) : Color(uiColor: .tertiaryLabel))

                    if prayer.name != entry.allPrayers.last?.name {
                        Spacer()
                    }
                }
            }
        }
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
