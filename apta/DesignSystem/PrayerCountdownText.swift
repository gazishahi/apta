import SwiftUI

/// Keep the time source and Apple's format style intact. Formatting a Date into
/// a String here would turn the countdown back into a frozen widget snapshot.
struct PrayerCountdownText: View {
    let start: Date
    let end: Date
    var minutesOnly = true
    var showsSuffix = false

    var body: some View {
        let style = PrayerCountdownStyle.timer(from: start, until: end, minutesOnly: minutesOnly)
        if showsSuffix {
            Text("\(TimeDataSource<Date>.currentDate, format: style) left")
        } else {
            Text(.currentDate, format: style)
        }
    }
}

enum PrayerCountdownStyle {
    static func timer(from start: Date, until end: Date, minutesOnly: Bool = true) -> SystemFormatStyle.Timer {
        // A delayed entry can already be expired. Keep the interval valid and
        // let the system clamp its countdown to zero, never count back upward.
        let lowerBound = min(start, end.addingTimeInterval(-1))
        return .init(countingDownIn: lowerBound..<end,
                     maxPrecision: .seconds(minutesOnly ? 60 : 1))
    }
}
