import WidgetKit
import CoreLocation
import Foundation

struct PrayerTimelineProvider: TimelineProvider {
    typealias Entry = PrayerWidgetEntry
    var displaysCalendarDay = false

    func placeholder(in context: Context) -> PrayerWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
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
        let calendar = SharedDefaults.prayerCalendar
        let today = calendar.startOfDay(for: now)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let boundaryPrayers = prayers(for: [today, tomorrow], location: location, settings: settings)
        var boundaryDates = boundaryPrayers.map(\.time)
        if displaysCalendarDay {
            // Calendar-day schedules roll at local midnight, including across DST.
            boundaryDates.append(tomorrow)
            if let followingDay = calendar.date(byAdding: .day, value: 1, to: tomorrow) {
                boundaryDates.append(followingDay)
            }
        }
        let upcomingBoundaries = Set(boundaryDates)
            .filter { $0 > now }
            .sorted()

        var entries = [buildEntry(for: now, location: location, settings: settings)]
        entries.append(contentsOf: upcomingBoundaries.map {
            buildEntry(for: $0, location: location, settings: settings)
        })

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func makeEntry(for date: Date) -> PrayerWidgetEntry {
        guard let location = storedLocation() else { return .noLocation }
        return buildEntry(for: date, location: location, settings: PrayerSettings.current)
    }

    private func buildEntry(for date: Date, location: CLLocation, settings: PrayerSettings) -> PrayerWidgetEntry {
        let calendar = SharedDefaults.prayerCalendar
        let surroundingDates = (-1...1).compactMap {
            calendar.date(byAdding: .day, value: $0, to: calendar.startOfDay(for: date))
        }
        let resolved = PrayerWindowResolver.resolve(
            at: date,
            prayers: prayers(for: surroundingDates, location: location, settings: settings),
            calendar: calendar
        )
        let displayPrayers = displaysCalendarDay
            ? calendarDaySalah(at: date, location: location, settings: settings, calendar: calendar)
            : resolved.displayPrayers

        return PrayerWidgetEntry(
            date: date,
            currentPrayer: resolved.currentPrayer?.name,
            nextPrayer: resolved.nextPrayer?.name,
            nextPrayerTime: resolved.nextPrayer?.time,
            previousPrayerTime: resolved.previousPrayer?.time,
            progressStartTime: resolved.progressStartTime,
            progressEndTime: resolved.progressEndTime,
            allPrayers: displayPrayers,
            hijriDateString: formatHijriDate(settings: settings, date: date),
            locationName: "",
            hasLocation: true,
            circularDisplayMode: .time
        )
    }

    /// Today's five prayers, or tomorrow's once today's Isha has started.
    private func calendarDaySalah(at date: Date, location: CLLocation, settings: PrayerSettings, calendar: Calendar) -> [PrayerTimeEntry] {
        let today = PrayerCalculationService.dailySalah(for: date, location: location, settings: settings, calendar: calendar)
        guard let isha = today.last, date >= isha.time,
              let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else { return today }
        return PrayerCalculationService.dailySalah(for: tomorrow, location: location, settings: settings, calendar: calendar)
    }

    private func prayers(for dates: [Date], location: CLLocation, settings: PrayerSettings) -> [PrayerTimeEntry] {
        dates
            .flatMap { date in
                PrayerCalculationService.calculate(for: date, location: location, settings: settings)
                    .filter { $0.name != .ishraq }
            }
            .sorted { $0.time < $1.time }
    }

    private func storedLocation() -> CLLocation? {
        let defaults = SharedDefaults.suite
        let lat = defaults.double(forKey: SharedDefaults.latitudeKey)
        let lon = defaults.double(forKey: SharedDefaults.longitudeKey)
        guard lat != 0 || lon != 0 else { return nil }
        return CLLocation(latitude: lat, longitude: lon)
    }

    private func formatHijriDate(settings: PrayerSettings, date: Date) -> String {
        let calendar = SharedDefaults.calendar(identifier: .islamicUmmAlQura)
        let adjusted = SharedDefaults.prayerCalendar.date(byAdding: .day, value: settings.hijriAdjustment, to: date) ?? date
        let formatter = DateFormatter()
        formatter.timeZone = SharedDefaults.prayerTimeZone
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en")
        formatter.dateFormat = "d MMMM y"
        return formatter.string(from: adjusted)
    }
}
