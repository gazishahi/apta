import WidgetKit
import CoreLocation
import Foundation
import WatchConnectivity

// Self-contained entry for watch complications
struct WatchEntry: TimelineEntry {
    let date: Date
    let nextPrayerName: String?
    let nextPrayerTime: Date?
    let previousPrayerName: String?
    let previousPrayerTime: Date?
    let upcomingPrayers: [(name: String, time: Date)]
    let hasLocation: Bool
    let isProUser: Bool

    var progressInterval: ClosedRange<Date>? {
        guard let previousPrayerTime, let nextPrayerTime,
              previousPrayerTime < nextPrayerTime else {
            return nil
        }
        return previousPrayerTime...nextPrayerTime
    }

    static var placeholder: WatchEntry {
        WatchEntry(
            date: Date(),
            nextPrayerName: "Maghrib",
            nextPrayerTime: Date().addingTimeInterval(3600),
            previousPrayerName: "Asr",
            previousPrayerTime: Date().addingTimeInterval(-3600),
            upcomingPrayers: [
                ("Isha", Date().addingTimeInterval(7200)),
                ("Fajr", Date().addingTimeInterval(14400)),
            ],
            hasLocation: true,
            isProUser: false
        )
    }

    static var noLocation: WatchEntry {
        WatchEntry(date: Date(), nextPrayerName: nil, nextPrayerTime: nil, previousPrayerName: nil,
                   previousPrayerTime: nil, upcomingPrayers: [], hasLocation: false, isProUser: false)
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
        let prayers  = prayers(spanningDaysFrom: now, location: location, settings: settings)

        // The system advances timer text and progress independently of this
        // timeline. Entries are only needed when the prayer data changes.
        let dates = Set(prayers.map(\.time).filter { $0 > now })

        var entries: [WatchEntry] = []
        entries.append(buildEntry(date: now, prayers: prayers, isProUser: isPro))
        for date in dates.sorted() {
            entries.append(buildEntry(date: date, prayers: prayers, isProUser: isPro))
        }

        // Request a daily extension of the multi-day timeline. The OS may defer
        // this request; it is not what drives the visible countdown.
        let calendar = SharedDefaults.prayerCalendar
        let nextMidnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        completion(Timeline(entries: entries, policy: .after(nextMidnight)))
    }

    // MARK: - Entry builders

    // Includes yesterday so entries before today's Fajr still have a previous
    // prayer to anchor the progress interval.
    private func prayers(spanningDaysFrom date: Date, location: CLLocation, settings: PrayerSettings) -> [PrayerTimeEntry] {
        let calendar = SharedDefaults.prayerCalendar
        let startOfDay = calendar.startOfDay(for: date)
        return (-1...2)
            .compactMap { calendar.date(byAdding: .day, value: $0, to: startOfDay) }
            .flatMap { PrayerCalculationService.calculate(for: $0, location: location, settings: settings) }
            .filter { $0.name != .ishraq }
            .sorted { $0.time < $1.time }
    }

    private func buildEntry(date: Date, prayers: [PrayerTimeEntry], isProUser: Bool) -> WatchEntry {
        let resolved = PrayerWindowResolver.resolve(at: date, prayers: prayers)
        let upcoming = prayers.filter { $0.time > date }
        let next = resolved.nextPrayer
        let previous = resolved.previousPrayer
        let rest = upcoming.dropFirst().prefix(2).map { ($0.name.rawValue, $0.time) }
        return WatchEntry(
            date: date,
            nextPrayerName: next?.name.rawValue,
            nextPrayerTime: next?.time,
            previousPrayerName: previous?.name.rawValue,
            previousPrayerTime: previous?.time,
            upcomingPrayers: Array(rest),
            hasLocation: true,
            isProUser: isProUser
        )
    }

    private func makeEntry(for date: Date) -> WatchEntry {
        guard let location = storedLocation() else { return .noLocation }
        let settings = storedPrayerSettings()
        let isPro    = storedIsProUser()
        return buildEntry(
            date: date,
            prayers: prayers(spanningDaysFrom: date, location: location, settings: settings),
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
        SharedDefaults.storeLocationPayload(ctx)
        if let manual = SharedDefaults.manualLocation {
            return CLLocation(latitude: manual.latitude, longitude: manual.longitude)
        }
        // Read the newest synchronized location, including an explicit clear.
        let defaults = SharedDefaults.suite
        let lat = defaults.double(forKey: SharedDefaults.latitudeKey)
        let lon = defaults.double(forKey: SharedDefaults.longitudeKey)
        guard lat != 0 || lon != 0 else { return nil }
        return CLLocation(latitude: lat, longitude: lon)
    }

    private func storedIsProUser() -> Bool {
        let storedIsPro = SharedDefaults.isProUser
        let defaults = SharedDefaults.suite
        let storedUpdatedAt = defaults.double(forKey: SharedDefaults.proStatusUpdatedAtKey)
        let ctx = applicationContext
        return ProStatusResolver.resolve(
            storedValue: storedIsPro,
            storedUpdatedAt: storedUpdatedAt,
            contextValue: ctx[SharedDefaults.isProUserKey] as? Bool,
            contextUpdatedAt: ctx[SharedDefaults.proStatusUpdatedAtKey] as? Double
        )
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
