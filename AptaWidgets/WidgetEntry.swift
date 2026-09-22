import WidgetKit
import Foundation

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let currentPrayer: PrayerName?
    let nextPrayer: PrayerName?
    let nextPrayerTime: Date?
    let previousPrayerTime: Date?
    let progressStartTime: Date?
    let progressEndTime: Date?
    let allPrayers: [PrayerTimeEntry]
    let hijriDateString: String
    let locationName: String
    let hasLocation: Bool
    let circularDisplayMode: CircularPrayerDisplayMode

    var progressInterval: ClosedRange<Date>? {
        guard let progressStartTime,
              let progressEndTime,
              progressStartTime < progressEndTime else {
            return nil
        }
        return progressStartTime...progressEndTime
    }

    /// The five obligatory prayers used by schedule-style widget rows.
    var salahPrayers: [PrayerTimeEntry] {
        allPrayers.filter { $0.name != .sunrise && $0.name != .ishraq }
    }

    /// The next calculated event, including Sunrise but excluding optional Ishraq.
    var nextPrayerEvent: PrayerTimeEntry? {
        guard let nextPrayer, let nextPrayerTime else { return nil }
        return PrayerTimeEntry(name: nextPrayer, time: nextPrayerTime)
    }

    var nextEventProgressInterval: ClosedRange<Date>? {
        progressInterval
    }

    static var placeholder: PrayerWidgetEntry {
        PrayerWidgetEntry(
            date: Date(),
            currentPrayer: .asr,
            nextPrayer: .maghrib,
            nextPrayerTime: Date().addingTimeInterval(3600),
            previousPrayerTime: Date().addingTimeInterval(-3600),
            progressStartTime: Date().addingTimeInterval(-3600),
            progressEndTime: Date().addingTimeInterval(3600),
            allPrayers: [
                PrayerTimeEntry(name: .fajr, time: Date()),
                PrayerTimeEntry(name: .dhuhr, time: Date()),
                PrayerTimeEntry(name: .asr, time: Date()),
                PrayerTimeEntry(name: .maghrib, time: Date().addingTimeInterval(3600)),
                PrayerTimeEntry(name: .isha, time: Date().addingTimeInterval(7200)),
            ],
            hijriDateString: "15 Ramadan 1447",
            locationName: "NY",
            hasLocation: true,
            circularDisplayMode: .time
        )
    }

    static var noLocation: PrayerWidgetEntry {
        PrayerWidgetEntry(
            date: Date(),
            currentPrayer: nil,
            nextPrayer: nil,
            nextPrayerTime: nil,
            previousPrayerTime: nil,
            progressStartTime: nil,
            progressEndTime: nil,
            allPrayers: [],
            hijriDateString: "",
            locationName: "",
            hasLocation: false,
            circularDisplayMode: .time
        )
    }
}
