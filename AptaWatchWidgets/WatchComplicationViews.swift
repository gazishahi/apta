import SwiftUI
import WidgetKit

// MARK: - Inline (free)

struct InlineComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        Group {
            if let name = entry.nextPrayerName, let time = entry.nextPrayerTime {
                Text("\(name) · \(shortTime(time))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .minimumScaleFactor(0.7)
            } else {
                Text("apta")
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Circular (free)

struct CircularComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                if let name = entry.nextPrayerName, let time = entry.nextPrayerTime {
                    Text(shortLabel(for: name))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(time, style: .timer)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 16))
                    Text("apta")
                        .font(.system(size: 10))
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 3)
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Circular progress ring (Pro only)

struct CircularProgressComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        Group {
            if entry.isProUser {
                if let name = entry.nextPrayerName, let interval = entry.progressInterval {
                    ProgressView(timerInterval: interval, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        Text(shortLabel(for: name))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .progressViewStyle(.circular)
                } else if let name = entry.nextPrayerName {
                    Text(shortLabel(for: name))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                } else {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 16))
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Corner progress arc (Pro only)

struct CornerProgressComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        Group {
            if entry.isProUser {
                if let name = entry.nextPrayerName, let time = entry.nextPrayerTime {
                    Text(cornerLabel(for: name))
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .widgetCurvesContent()
                        .widgetLabel {
                            Gauge(value: progress) {
                                EmptyView()
                            } currentValueLabel: {
                                EmptyView()
                            } minimumValueLabel: {
                                Text(remainingText(until: time))
                            } maximumValueLabel: {
                                Text(shortTime(time))
                            }
                        }
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.clear, for: .widget)
    }

    // Progress at this entry's date; the timeline's dense entries keep it moving.
    private var progress: Double {
        guard let interval = entry.progressInterval else { return 0 }
        let total = interval.upperBound.timeIntervalSince(interval.lowerBound)
        guard total > 0 else { return 0 }
        let elapsed = entry.date.timeIntervalSince(interval.lowerBound)
        return min(max(elapsed / total, 0), 1)
    }

    private func remainingText(until time: Date) -> String {
        let minutes = Int((time.timeIntervalSince(entry.date) / 60).rounded(.up))
        if minutes >= 60 {
            return "\(minutes / 60)h"
        }
        return "\(max(minutes, 0))m"
    }
}

// MARK: - Rectangular (Pro only)

struct RectangularComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        if entry.isProUser {
            proView
        } else {
            lockedView
        }
    }

    private var proView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let name = entry.nextPrayerName, let time = entry.nextPrayerTime {
                HStack {
                    Text(name.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(1)
                    Spacer()
                    Text(time, style: .timer)
                        .font(.system(size: 13, weight: .thin, design: .monospaced))
                        .monospacedDigit()
                }
                ForEach(Array(entry.upcomingPrayers.enumerated()), id: \.offset) { _, prayer in
                    HStack {
                        Text(prayer.name)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(shortTime(prayer.time))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .containerBackground(.clear, for: .widget)
    }

    private var lockedView: some View {
        HStack {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text("apta Pro")
                .font(.system(size: 12, weight: .medium))
            Spacer()
        }
        .padding(.horizontal, 4)
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Smart Stack countdown (Pro only)

/// Athan Utility-style layout: current prayer with time remaining, the next
/// prayer's time, and a progress bar across the current window.
struct SmartStackComplicationView: View {
    let entry: WatchEntry

    private let accent = Color(red: 0.56, green: 0.75, blue: 1.0)

    var body: some View {
        Group {
            if entry.isProUser {
                proView
            } else {
                lockedView
            }
        }
        .containerBackground(.clear, for: .widget)
    }

    @ViewBuilder
    private var proView: some View {
        if let nextName = entry.nextPrayerName, let nextTime = entry.nextPrayerTime {
            // Between Sunrise and Dhuhr there is no prayer window to be "in",
            // so the first line points forward ("Dhuhr in 2h") instead of
            // counting down a window ("Sunrise • 2h left").
            let inSunriseGap = entry.previousPrayerName == PrayerName.sunrise.rawValue
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    if inSunriseGap {
                        Text("\(nextName) in \(Text(nextTime, style: .relative))")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .monospacedDigit()
                    } else {
                        if let currentName = entry.previousPrayerName {
                            Text(currentName)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("•")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                        }
                        Text("\(Text(nextTime, style: .relative)) left")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(accent)
                .widgetAccentable()
                .lineLimit(1)
                .minimumScaleFactor(0.6)

                if inSunriseGap, let following = entry.upcomingPrayers.first {
                    Text("\(following.name) \(shortTime(following.time))")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else {
                    Text("\(nextName) \(shortTime(nextTime))")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                if let interval = entry.progressInterval {
                    ProgressView(timerInterval: interval, countsDown: false) {
                        EmptyView()
                    } currentValueLabel: {
                        EmptyView()
                    }
                    .progressViewStyle(.linear)
                    .tint(accent)
                }
            }
            .padding(.horizontal, 2)
        } else {
            HStack {
                Image(systemName: "moon.stars")
                Text("apta")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                Spacer()
            }
        }
    }

    private var lockedView: some View {
        HStack {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
            Text("apta Pro")
                .font(.system(size: 12, weight: .medium))
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Corner (Pro only)

struct CornerComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        Group {
            if entry.isProUser {
                if let name = entry.nextPrayerName, let time = entry.nextPrayerTime {
                    Text(shortTime(time))
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .monospacedDigit()
                        .widgetCurvesContent()
                        .widgetLabel {
                            Text(name.uppercased())
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

struct CornerCountdownComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        Group {
            if entry.isProUser {
                if let name = entry.nextPrayerName, let time = entry.nextPrayerTime {
                    // Live timers don't survive widgetCurvesContent (their width
                    // changes every second), so the timer lives in the curved
                    // widget label and the prayer name takes the big inner slot.
                    Text(cornerLabel(for: name))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .widgetCurvesContent()
                        .widgetLabel {
                            Text(time, style: .timer)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                        }
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(.clear, for: .widget)
    }
}

// MARK: - Helpers

private func shortTime(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "h:mm"
    return f.string(from: date)
}

private func shortLabel(for name: String) -> String {
    PrayerName(rawValue: name)?.shortLabel ?? String(name.prefix(3)).uppercased()
}

private func cornerLabel(for name: String) -> String {
    PrayerName(rawValue: name)?.cornerLabel ?? name.uppercased()
}
