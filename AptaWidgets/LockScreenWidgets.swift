import SwiftUI
import WidgetKit

// MARK: - Inline (accessoryInline)

struct InlinePrayerWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        if let next = entry.nextPrayer, let time = entry.nextPrayerTime {
            Text("\(next.rawValue) \(formatTime(time))")
        } else {
            Text("apta")
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = PrayerSettings.current.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Circular (accessoryCircular)

struct CircularPrayerWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        if let next = entry.nextPrayer, let time = entry.nextPrayerTime {
            let progress = progressToNextPrayer(nextTime: time)
            Gauge(value: progress) {
                Text("")
            } currentValueLabel: {
                VStack(spacing: 0) {
                    Text(abbreviation(next))
                        .font(.system(size: 12, weight: .medium))
                    Text(formatTimeShort(time))
                        .font(.system(size: 11, weight: .light))
                }
            }
            .gaugeStyle(.accessoryCircular)
        } else {
            Text("--")
                .font(.caption)
        }
    }

    private func abbreviation(_ prayer: PrayerName) -> String {
        switch prayer {
        case .fajr: return "FJR"
        case .sunrise: return "SUN"
        case .dhuhr: return "DHR"
        case .asr: return "ASR"
        case .maghrib: return "MGH"
        case .isha: return "ISH"
        case .ishraq: return "ISH"
        }
    }

    private func formatTimeShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = PrayerSettings.current.timeFormat == .twelve ? "h:mm" : "HH:mm"
        return formatter.string(from: date)
    }

    private func progressToNextPrayer(nextTime: Date) -> Double {
        let diff = nextTime.timeIntervalSince(entry.date)
        let maxGap: TimeInterval = 4 * 3600
        guard diff > 0 else { return 1.0 }
        return max(0, 1.0 - (diff / maxGap))
    }
}

// MARK: - Rectangular (accessoryRectangular)

struct RectangularPrayerWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        if let next = entry.nextPrayer, let time = entry.nextPrayerTime {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(next.rawValue.uppercased())
                        .font(.system(size: 13, weight: .medium))
                        .kerning(1.5)
                    Spacer()
                    Text(formatTime(time))
                        .font(.system(size: 13, weight: .regular))
                }

                let progress = progressToNextPrayer(nextTime: time)
                ProgressView(value: progress)

                Text(countdown(to: time))
                    .font(.system(size: 11, weight: .light))
            }
        } else {
            Text("Open apta")
                .font(.caption)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = PrayerSettings.current.timeFormat == .twelve ? "h:mm a" : "HH:mm"
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

    private func progressToNextPrayer(nextTime: Date) -> Double {
        let diff = nextTime.timeIntervalSince(entry.date)
        let maxGap: TimeInterval = 4 * 3600
        guard diff > 0 else { return 1.0 }
        return max(0, 1.0 - (diff / maxGap))
    }
}
