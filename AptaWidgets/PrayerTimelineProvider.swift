import WidgetKit
import CoreLocation
import Foundation

struct PrayerTimelineProvider: TimelineProvider {
    typealias Entry = PrayerWidgetEntry

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        completion(makeEntry(for: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PrayerWidgetEntry>) -> Void) {
        let now = Date()
        guard let location = storedLocation() else {
            let timeline = Timeline(entries: [PrayerWidgetEntry.noLocation], policy: .after(now.addingTimeInterval(900)))
            completion(timeline)
            return
        }

        let settings = PrayerSettings.current
        let today = PrayerCalculationService.calculate(for: now, location: location, settings: settings)
            .filter { $0.name != .sunrise }

        let calendar = Calendar(identifier: .gregorian)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let tomorrowPrayers = PrayerCalculationService.calculate(for: tomorrow, location: location, settings: settings)
            .filter { $0.name != .sunrise }

        var entries: [PrayerWidgetEntry] = []

        // Create an entry at each prayer transition
        let allTimes = today + tomorrowPrayers
        let futureTimes = allTimes.filter { $0.time > now }

        // Entry for "now"
        entries.append(buildEntry(date: now, allToday: today, allTomorrow: tomorrowPrayers, location: location, settings: settings))

        // Entry at each future prayer time (so the "next prayer" updates)
        for prayer in futureTimes.prefix(10) {
            entries.append(buildEntry(date: prayer.time, allToday: today, allTomorrow: tomorrowPrayers, location: location, settings: settings))
        }

        _ = entries.last?.date ?? now.addingTimeInterval(3600)
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func buildEntry(date: Date, allToday: [PrayerTimeEntry], allTomorrow: [PrayerTimeEntry], location: CLLocation, settings: PrayerSettings) -> PrayerWidgetEntry {
        let upcoming = allToday.filter { $0.time > date }
        let next = upcoming.first ?? allTomorrow.first

        let hijri = formatHijriDate(settings: settings, date: date)

        return PrayerWidgetEntry(
            date: date,
            nextPrayer: next?.name,
            nextPrayerTime: next?.time,
            allPrayers: allToday,
            hijriDateString: hijri,
            locationName: "",
            hasLocation: true
        )
    }

    private func makeEntry(for date: Date) -> PrayerWidgetEntry {
        guard let location = storedLocation() else { return .noLocation }
        let settings = PrayerSettings.current
        let prayers = PrayerCalculationService.calculate(for: date, location: location, settings: settings)
            .filter { $0.name != .sunrise }

        let upcoming = prayers.filter { $0.time > date }
        let next = upcoming.first

        return PrayerWidgetEntry(
            date: date,
            nextPrayer: next?.name,
            nextPrayerTime: next?.time,
            allPrayers: prayers,
            hijriDateString: formatHijriDate(settings: settings, date: date),
            locationName: "",
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

    private func formatHijriDate(settings: PrayerSettings, date: Date) -> String {
        let calendar = Calendar(identifier: .islamicUmmAlQura)
        let adjusted = Calendar.current.date(byAdding: .day, value: settings.hijriAdjustment, to: date) ?? date
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en")
        formatter.dateFormat = "d MMMM y"
        return formatter.string(from: adjusted)
    }
}
