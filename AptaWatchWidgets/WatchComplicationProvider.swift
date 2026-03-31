import WidgetKit
import CoreLocation
import Foundation
import WatchConnectivity

// Self-contained entry for watch complications
struct WatchEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String?
    let nextPrayerTime: Date?
    let upcomingPrayers: [(name: String, time: Date)]
    let hasLocation: Bool
    let isProUser: Bool

    static var placeholder: WatchEntry {
        WatchEntry(
            date: Date(),
            nextPrayerName: "Maghrib",
            nextPrayerTime: Date().addingTimeInterval(3600),
            upcomingPrayers: [
                ("Isha", Date().addingTimeInterval(7200)),
                ("Fajr", Date().addingTimeInterval(14400)),
            ],
            hasLocation: true,
            isProUser: false
        )
    }

    static var noLocation: WatchEntry {
        WatchEntry(date: Date(), nextPrayerName: nil, nextPrayerTime: nil,
                   upcomingPrayers: [], hasLocation: false, isProUser: false)
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
            let retry = Timeline(entries: [WatchEntry.noLocation], policy: .after(now.addingTimeInterval(900)))
            completion(retry)
            return
        }

        let settings = storedPrayerSettings()
        let isPro    = storedIsProUser()
        let calendar = Calendar(identifier: .gregorian)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!

        let today = PrayerCalculationService.calculate(for: now, location: location, settings: settings)
            .filter { $0.name != .ishraq }
        let tomorrowPrayers = PrayerCalculationService.calculate(for: tomorrow, location: location, settings: settings)
            .filter { $0.name != .ishraq }

        var entries: [WatchEntry] = []
        entries.append(buildEntry(date: now, allToday: today, allTomorrow: tomorrowPrayers, isProUser: isPro))

        let allTimes = today + tomorrowPrayers
        for prayer in allTimes.filter({ $0.time > now }).prefix(10) {
            entries.append(buildEntry(date: prayer.time, allToday: today, allTomorrow: tomorrowPrayers, isProUser: isPro))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    // MARK: - Entry builders

    private func buildEntry(date: Date, allToday: [PrayerTimeEntry], allTomorrow: [PrayerTimeEntry], isProUser: Bool) -> WatchEntry {
        let upcoming = allToday.filter { $0.time > date }
        let next = upcoming.first ?? allTomorrow.first
        let rest = upcoming.dropFirst().prefix(2).map { ($0.name.rawValue, $0.time) }
        return WatchEntry(
            date: date,
            nextPrayerName: next?.name.rawValue,
            nextPrayerTime: next?.time,
            upcomingPrayers: Array(rest),
            hasLocation: true,
            isProUser: isProUser
        )
    }

    private func makeEntry(for date: Date) -> WatchEntry {
        guard let location = storedLocation() else { return .noLocation }
        let settings  = storedPrayerSettings()
        let isPro     = storedIsProUser()
        let prayers   = PrayerCalculationService.calculate(for: date, location: location, settings: settings)
            .filter { $0.name != .ishraq }
        let upcoming  = prayers.filter { $0.time > date }
        let next      = upcoming.first
        let rest      = upcoming.dropFirst().prefix(2).map { ($0.name.rawValue, $0.time) }
        return WatchEntry(
            date: date,
            nextPrayerName: next?.name.rawValue,
            nextPrayerTime: next?.time,
            upcomingPrayers: Array(rest),
            hasLocation: true,
            isProUser: isPro
        )
    }

    // MARK: - Data sources
    // Primary: WCSession.receivedApplicationContext (persisted by system, no app-group dependency).
    // Fallback: SharedDefaults.suite (works when app group is accessible).

    private var applicationContext: [String: Any] {
        guard WCSession.isSupported() else { return [:] }
        return WCSession.default.receivedApplicationContext
    }

    private func storedLocation() -> CLLocation? {
        // Try application context first
        let ctx = applicationContext
        if let lat = ctx[SharedDefaults.latitudeKey] as? Double,
           let lon = ctx[SharedDefaults.longitudeKey] as? Double,
           lat != 0 || lon != 0 {
            return CLLocation(latitude: lat, longitude: lon)
        }
        // Fallback to shared defaults
        let defaults = SharedDefaults.suite
        let lat = defaults.double(forKey: SharedDefaults.latitudeKey)
        let lon = defaults.double(forKey: SharedDefaults.longitudeKey)
        guard lat != 0 || lon != 0 else { return nil }
        return CLLocation(latitude: lat, longitude: lon)
    }

    private func storedIsProUser() -> Bool {
        let ctx = applicationContext
        if let isPro = ctx[SharedDefaults.isProUserKey] as? Bool {
            return isPro
        }
        return SharedDefaults.suite.bool(forKey: SharedDefaults.isProUserKey)
    }

    private func storedPrayerSettings() -> PrayerSettings {
        let ctx = applicationContext
        if let data = ctx["prayerSettings"] as? Data,
           let settings = try? JSONDecoder().decode(PrayerSettings.self, from: data) {
            return settings
        }
        return PrayerSettings.current
    }
}
