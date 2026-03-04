import WidgetKit
import Foundation

struct PrayerWidgetEntry: TimelineEntry {
    let date: Date
    let nextPrayer: PrayerName?
    let nextPrayerTime: Date?
    let allPrayers: [PrayerTimeEntry]
    let hijriDateString: String
    let locationName: String
    let hasLocation: Bool

    static var placeholder: PrayerWidgetEntry {
        PrayerWidgetEntry(
            date: Date(),
            nextPrayer: .maghrib,
            nextPrayerTime: Date().addingTimeInterval(3600),
            allPrayers: [
                PrayerTimeEntry(name: .fajr, time: Date()),
                PrayerTimeEntry(name: .dhuhr, time: Date()),
                PrayerTimeEntry(name: .asr, time: Date()),
                PrayerTimeEntry(name: .maghrib, time: Date().addingTimeInterval(3600)),
                PrayerTimeEntry(name: .isha, time: Date().addingTimeInterval(7200)),
            ],
            hijriDateString: "15 Ramadan 1447",
            locationName: "NY",
            hasLocation: true
        )
    }

    static var noLocation: PrayerWidgetEntry {
        PrayerWidgetEntry(
            date: Date(),
            nextPrayer: nil,
            nextPrayerTime: nil,
            allPrayers: [],
            hijriDateString: "",
            locationName: "",
            hasLocation: false
        )
    }
}
