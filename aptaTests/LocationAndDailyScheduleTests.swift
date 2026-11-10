import CoreLocation
import Foundation
import Testing
@testable import apta

@MainActor
struct CurrentLocationRecoveryTests {
    @Test func settingsDetourSurvivesRelaunchAndConsumesOnlyAfterAuthorization() {
        let suiteName = "apta-location-recovery-\(UUID())"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        CurrentLocationRecovery(defaults: defaults).request()
        let relaunched = CurrentLocationRecovery(defaults: UserDefaults(suiteName: suiteName)!)
        #expect(!relaunched.consumeIfAuthorized(.denied))
        #expect(!relaunched.consumeIfAuthorized(.restricted))
        #expect(!relaunched.consumeIfAuthorized(.notDetermined))
        #expect(relaunched.consumeIfAuthorized(.authorizedWhenInUse))
        #expect(!relaunched.consumeIfAuthorized(.authorizedAlways))
    }

    @Test func independentPermissionChangesDoNotSwitchAwayFromManualLocation() {
        let suiteName = "apta-location-recovery-\(UUID())"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let recovery = CurrentLocationRecovery(defaults: defaults)

        #expect(!recovery.consumeIfAuthorized(.authorizedWhenInUse))
        #expect(!recovery.consumeIfAuthorized(.authorizedAlways))
    }

    @Test func choosingAnotherCityCancelsPendingSwitch() {
        let suiteName = "apta-location-recovery-\(UUID())"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let recovery = CurrentLocationRecovery(defaults: defaults)

        recovery.request()
        recovery.cancel()
        #expect(!recovery.consumeIfAuthorized(.authorizedAlways))
        recovery.request()
        #expect(recovery.consumeIfAuthorized(.authorizedAlways))
    }
}

@MainActor
struct CalendarDayPrayerScheduleTests {
    @Test func keepsAllFiveAfterIshaAndRollsAtTheSelectedLocationsMidnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let location = CLLocation(latitude: 35.6762, longitude: 139.6503)
        let day = calendar.date(from: DateComponents(year: 2026, month: 10, day: 20))!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: day)!
        let todaysPrayers = schedule(at: day, location: location, calendar: calendar)
        let tomorrowsPrayers = schedule(at: tomorrow, location: location, calendar: calendar)
        let beforeMidnight = tomorrow.addingTimeInterval(-1)

        #expect(todaysPrayers.map(\.name) == [.fajr, .dhuhr, .asr, .maghrib, .isha])
        #expect(schedule(at: beforeMidnight, location: location, calendar: calendar).map(\.time)
                == todaysPrayers.map(\.time))
        #expect(schedule(at: tomorrow, location: location, calendar: calendar).map(\.time)
                == tomorrowsPrayers.map(\.time))
        #expect(todaysPrayers.first?.time != tomorrowsPrayers.first?.time)

        // Existing widgets retain their next-available-day behavior.
        let existing = PrayerWindowResolver.resolve(
            at: beforeMidnight, prayers: todaysPrayers + tomorrowsPrayers, calendar: calendar
        )
        #expect(existing.displayPrayers.map(\.time) == tomorrowsPrayers.map(\.time))
    }

    @Test func localDaySelectionSurvivesShortAndLongDaylightSavingDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let location = CLLocation(latitude: 42.3601, longitude: -71.0589)
        for (month, day, hours) in [(3, 8, 23), (11, 1, 25)] {
            let start = calendar.date(from: DateComponents(year: 2026, month: month, day: day))!
            let midnight = calendar.date(byAdding: .day, value: 1, to: start)!
            #expect(midnight.timeIntervalSince(start) == Double(hours * 3600))
            let today = schedule(at: start, location: location, calendar: calendar)
            let tomorrow = schedule(at: midnight, location: location, calendar: calendar)
            #expect(today.count == 5 && tomorrow.count == 5)
            for instant in [midnight.addingTimeInterval(-1), midnight] {
                let result = schedule(at: instant, location: location, calendar: calendar)
                let expected = instant < midnight ? today : tomorrow
                #expect(result.map(\.time) == expected.map(\.time))
            }
        }
    }

    @Test func retainsAfterMidnightIshaAndExcludesSupplementaryEvents() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Oslo")!
        let date = calendar.date(from: DateComponents(year: 2026, month: 6, day: 21))!
        let midnight = calendar.date(byAdding: .day, value: 1, to: date)!
        let location = CLLocation(latitude: 59.9139, longitude: 10.7522)
        var settings = PrayerSettings()
        settings.showIshraq = true
        let result = PrayerCalculationService.dailySalah(
            for: date, location: location, settings: settings, calendar: calendar
        )
        #expect(result.map(\.name) == [.fajr, .dhuhr, .asr, .maghrib, .isha])
        let isha = try #require(result.last)
        #expect(isha.time >= midnight)
        let lateEvening = PrayerCalculationService.dailySalah(
            for: midnight.addingTimeInterval(-1), location: location, settings: settings, calendar: calendar
        )
        #expect(lateEvening.map(\.time) == result.map(\.time))
    }

    private func schedule(at date: Date, location: CLLocation, calendar: Calendar) -> [PrayerTimeEntry] {
        PrayerCalculationService.dailySalah(
            for: date, location: location, settings: PrayerSettings(), calendar: calendar
        )
    }
}
