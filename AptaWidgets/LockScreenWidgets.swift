import SwiftUI
import WidgetKit

struct FivePrayersWidgetView: View {
    let entry: PrayerWidgetEntry

    private var prayers: [PrayerTimeEntry] { entry.salahPrayers }

    var body: some View {
        if prayers.count == 5 {
            VStack(spacing: 4) {
                ForEach(0..<3) { row in
                    HStack(spacing: 8) {
                        prayerCell(prayers[row * 2])
                        if row * 2 + 1 < prayers.count {
                            prayerCell(prayers[row * 2 + 1])
                        } else {
                            Text(dateLabel)
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                }
            }
        } else {
            Text(entry.hasLocation ? "Prayer times unavailable" : "Open apta to set location")
                .font(.caption)
        }
    }

    private func prayerCell(_ prayer: PrayerTimeEntry) -> some View {
        HStack(spacing: 2) {
            Text(prayer.name.shortLabel)
                .font(.system(size: 9, weight: .medium))
            Spacer(minLength: 0)
            Text(formatTime(prayer.time))
                .font(.system(size: 11, weight: .medium))
                .monospacedDigit()
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(prayer.name.rawValue), \(formatTime(prayer.time))")
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = SharedDefaults.prayerTimeZone
        formatter.dateFormat = PrayerSettings.current.timeFormat == .twelve ? "h:mma" : "HH:mm"
        return formatter.string(from: date)
    }

    private var dateLabel: String {
        if let first = prayers.first,
           !SharedDefaults.prayerCalendar.isDate(first.time, inSameDayAs: entry.date) {
            return "Tomorrow"
        }
        let formatter = DateFormatter()
        formatter.timeZone = SharedDefaults.prayerTimeZone
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter.string(from: entry.date)
    }
}

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
        formatter.timeZone = SharedDefaults.prayerTimeZone
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
        formatter.timeZone = SharedDefaults.prayerTimeZone
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
        formatter.timeZone = SharedDefaults.prayerTimeZone
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
        formatter.timeZone = SharedDefaults.prayerTimeZone
        formatter.dateFormat = PrayerSettings.current.timeFormat == .twelve ? "h:mm a" : "HH:mm"
        return formatter.string(from: date)
    }
}
