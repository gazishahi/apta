import SwiftUI
import WidgetKit

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

// MARK: - Circular Lock Screen Widget

struct CircularPrayerWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        if let next = entry.nextPrayer, let time = entry.nextPrayerTime {
            Group {
                if let interval = entry.progressInterval {
                    ProgressView(timerInterval: interval, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        compactLabel(next: next, time: time)
                    }
                    .progressViewStyle(.circular)
                } else {
                    compactLabel(next: next, time: time)
                }
            }
        } else {
            Text("--").font(.caption)
        }
    }

    private func compactLabel(next: PrayerName, time: Date) -> some View {
        VStack(spacing: 0) {
            Text(abbreviation(next))
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(formatTime(time))
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .monospacedDigit()
        }
        .multilineTextAlignment(.center)
    }

    private func abbreviation(_ prayer: PrayerName) -> String {
        switch prayer {
        case .fajr: return "FJR"
        case .sunrise: return "SUN"
        case .dhuhr: return "DHR"
        case .asr: return "ASR"
        case .maghrib: return "MGH"
        case .isha: return "ISH"
        case .ishraq: return "ISQ"
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = PrayerSettings.current.timeFormat == .twelve ? "h:mm" : "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Rectangular Lock Screen Widget

struct RectangularPrayerWidgetView: View {
    let entry: PrayerWidgetEntry

    var body: some View {
        if let next = entry.nextPrayer, let time = entry.nextPrayerTime {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(next.rawValue.uppercased())
                        .font(.system(size: 13, weight: .medium))
                        .kerning(1.5)
                    Spacer()
                    Text(formatTime(time))
                        .font(.system(size: 12, weight: .regular))
                }
                if let interval = entry.progressInterval {
                    ProgressView(timerInterval: interval, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.linear)
                } else {
                    ProgressView(value: 0)
                        .progressViewStyle(.linear)
                }
                Text(time, style: .timer)
                    .font(.system(size: 11, weight: .light))
            }
        } else {
            Text("Open apta").font(.caption)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = PrayerSettings.current.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }
}
