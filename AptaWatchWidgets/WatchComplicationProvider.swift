import WidgetKit
import CoreLocation
import Foundation

// Self-contained entry for watch complications
struct WatchEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String?
    let nextPrayerTime: Date?
    let upcomingPrayers: [(name: String, time: Date)]
    let hasLocation: Bool

    static var placeholder: WatchEntry {
        WatchEntry(
            date: Date(),
            nextPrayerName: "Maghrib",
            nextPrayerTime: Date().addingTimeInterval(3600),
            upcomingPrayers: [
                ("Isha", Date().addingTimeInterval(7200)),
                ("Fajr", Date().addingTimeInterval(14400)),
            ],
            hasLocation: true
        )
    }

    static var noLocation: WatchEntry {
        WatchEntry(date: Date(), nextPrayerName: nil, nextPrayerTime: nil, upcomingPrayers: [], hasLocation: false)
    }
}

struct WatchComplicationProvider: TimelineProvider {
    typealias Entry = WatchEntry

    func placeholder(in context: Context) -> WatchEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (WatchEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchEntry>) -> Void) {
        let now = Date()
        guard let location = storedLocation() else {
            let timeline = Timeline(entries: [WatchEntry.noLocation], policy: .after(now.addingTimeInterval(900)))
            completion(timeline)
            return
        }

        let settings = PrayerSettings.current
        let today = PrayerCalculationService.calculate(for: now, location: location, settings: settings)
            .filter { $0.name != .sunrise && $0.name != .ishraq }

        let calendar = Calendar(identifier: .gregorian)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let tomorrowPrayers = PrayerCalculationService.calculate(for: tomorrow, location: location, settings: settings)
            .filter { $0.name != .sunrise && $0.name != .ishraq }

        var entries: [WatchEntry] = []
        entries.append(buildEntry(date: now, allToday: today, allTomorrow: tomorrowPrayers))

        let allTimes = today + tomorrowPrayers
        for prayer in allTimes.filter({ $0.time > now }).prefix(10) {
            entries.append(buildEntry(date: prayer.time, allToday: today, allTomorrow: tomorrowPrayers))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func buildEntry(date: Date, allToday: [PrayerTimeEntry], allTomorrow: [PrayerTimeEntry]) -> WatchEntry {
        let upcoming = allToday.filter { $0.time > date }
        let next = upcoming.first ?? allTomorrow.first
        let rest = upcoming.dropFirst().prefix(2).map { ($0.name.rawValue, $0.time) }
        return WatchEntry(
            date: date,
            nextPrayerName: next?.name.rawValue,
            nextPrayerTime: next?.time,
            upcomingPrayers: Array(rest),
            hasLocation: true
        )
    }

    private func makeEntry(for date: Date) -> WatchEntry {
        guard let location = storedLocation() else { return .noLocation }
        let settings = PrayerSettings.current
        let prayers = PrayerCalculationService.calculate(for: date, location: location, settings: settings)
            .filter { $0.name != .sunrise && $0.name != .ishraq }
        let upcoming = prayers.filter { $0.time > date }
        let next = upcoming.first
        let rest = upcoming.dropFirst().prefix(2).map { ($0.name.rawValue, $0.time) }
        return WatchEntry(
            date: date,
            nextPrayerName: next?.name.rawValue,
            nextPrayerTime: next?.time,
            upcomingPrayers: Array(rest),
            hasLocation: true
        )
    }

    private func storedLocation() -> CLLocation? {
        let defaults = SharedDefaults.suite
        let lat = defaults.double(forKey: SharedDefaults.latitudeKey)
        let lon = defaults.double(forKey: SharedDefaults.longitudeKey)
        guard lat != 0 || lon != 0 else { return nil }
        return CLLocation(latitude: lat, longitude: lon)
    }
}
