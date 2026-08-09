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
    let displayMode: CircularPrayerDisplayMode

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
            Text(next.shortLabel)
                .font(.system(size: displayMode == .countdown ? 10 : 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if displayMode == .countdown {
                Text(time, style: .timer)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)
                    .monospacedDigit()
            } else {
                Text(formatTime(time))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .monospacedDigit()
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, displayMode == .countdown ? 4 : 0)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = PrayerSettings.current.timeFormat == .twelve ? "h:mm" : "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Circular next prayer (no ring)

struct CircularCountdownWidgetView: View {
    let entry: PrayerWidgetEntry
    let displayMode: CircularPrayerDisplayMode

    var body: some View {
        if let next = entry.nextPrayer, let time = entry.nextPrayerTime {
            VStack(spacing: 0) {
                Text(next.shortLabel)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if displayMode == .countdown {
                    Text(time, style: .timer)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                } else {
                    Text(formatTime(time))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 3)
        } else {
            Text("--").font(.caption)
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
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(next.rawValue.uppercased())
                        .font(.system(size: 15, weight: .medium))
                        .kerning(1.5)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Text(formatTime(time))
                        .font(.system(size: 14, weight: .regular))
                        .monospacedDigit()
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
                    .font(.system(size: 13, weight: .regular))
                    .monospacedDigit()
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
