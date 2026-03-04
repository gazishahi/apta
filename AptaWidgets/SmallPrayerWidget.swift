import SwiftUI
import WidgetKit

struct SmallPrayerWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        if !entry.hasLocation {
            Text("Open apta to set location")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(entry.allPrayers) { prayer in
                    let isNext = prayer.name == entry.nextPrayer
                    HStack(spacing: 0) {
                        Text(isNext ? ">" : " ")
                            .font(.system(size: 12, weight: .medium))
                            .frame(width: 10, alignment: .leading)
                        Text(prayer.name.rawValue.uppercased())
                            .font(.system(size: 12, weight: .regular))
                            .kerning(1.5)
                        Spacer()
                        Text(formatTime(prayer.time))
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundStyle(isNext ? Color(uiColor: .label) : Color(uiColor: .tertiaryLabel))
                }
            }
            .padding(2)
        }
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
