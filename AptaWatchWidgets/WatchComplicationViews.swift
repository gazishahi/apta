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
        VStack(spacing: 1) {
            if let name = entry.nextPrayerName, let time = entry.nextPrayerTime {
                Text(String(name.prefix(3)).uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .minimumScaleFactor(0.7)
                Text(time, style: .timer)
                    .font(.system(size: 9, weight: .thin, design: .monospaced))
                    .minimumScaleFactor(0.6)
                    .monospacedDigit()
            } else {
                Image(systemName: "moon.stars")
                    .font(.system(size: 14))
                Text("apta")
                    .font(.system(size: 9))
            }
        }
        .containerBackground(.clear, for: .widget)
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

// MARK: - Corner (Pro only)

struct CornerComplicationView: View {
    let entry: WatchEntry

    var body: some View {
        Group {
            if entry.isProUser {
                if let name = entry.nextPrayerName, let time = entry.nextPrayerTime {
                    VStack(spacing: 0) {
                        Text(String(name.prefix(3)).uppercased())
                            .font(.system(size: 11, weight: .semibold))
                        Text(shortTime(time))
                            .font(.system(size: 9, weight: .thin, design: .monospaced))
                            .monospacedDigit()
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
