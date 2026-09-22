//
//  aptaTests.swift
//  aptaTests
//
//  Created by Gazi Shahi on 3/3/26.
//

import Foundation
import CoreLocation
import Testing
import UserNotifications
import SwiftUI
@testable import apta

struct LivePrayerCountdownTests {
    private let end = Date(timeIntervalSince1970: 2_000_000_000)

    @Test func sameSystemStyleAdvancesAcrossReporterScreenshots() {
        let style = PrayerCountdownStyle.timer(from: end.addingTimeInterval(-3600), until: end)
            .locale(Locale(identifier: "en_US"))
        // One unchanged style, sampled at 4:56:26 and 5:08:23 for a 5:28 target.
        #expect(String(style.format(end.addingTimeInterval(-1894)).characters) == "31 minutes")
        #expect(String(style.format(end.addingTimeInterval(-1177)).characters) == "19 minutes")
    }

    @Test func nativeStyleProvidesItsOwnNextUpdateDate() throws {
        let style = PrayerCountdownStyle.timer(from: end.addingTimeInterval(-3600), until: end)
        let now = end.addingTimeInterval(-1177)
        let update = try #require(style.discreteInput(after: now))
        #expect(update > now)
        #expect(update.timeIntervalSince(now) <= 60)
        #expect(style.format(now) != style.format(update))
    }

    @Test func minutePrecisionNeverDisplaysSecondsAndStopsAtZero() {
        let style = PrayerCountdownStyle.timer(from: end.addingTimeInterval(-7200), until: end)
            .locale(Locale(identifier: "en_US"))
        #expect(String(style.format(end.addingTimeInterval(-3780)).characters) == "1 hour, 3 minutes")
        for offset in [-59.0, -1, 0, 1, 60, 3600] {
            #expect(String(style.format(end.addingTimeInterval(offset)).characters) == "0 minutes")
        }
    }

    @Test func secondsPrecisionPreservesExistingRectangularCountdown() {
        let style = PrayerCountdownStyle.timer(from: end.addingTimeInterval(-3600), until: end,
                                               minutesOnly: false).locale(Locale(identifier: "en_US"))
        #expect(String(style.format(end.addingTimeInterval(-1177)).characters) == "19:37")
        #expect(style.format(end) == style.format(end.addingTimeInterval(120)))
    }

    @Test func expiredOrZeroLengthEntryHasAValidStoppedTimer() {
        for start in [end, end.addingTimeInterval(60)] {
            let style = PrayerCountdownStyle.timer(from: start, until: end)
                .locale(Locale(identifier: "en_US"))
            #expect(String(style.format(end.addingTimeInterval(60)).characters) == "0 minutes")
        }
    }

    @Test func systemStyleSurvivesSerialization() throws {
        let style = PrayerCountdownStyle.timer(from: end.addingTimeInterval(-7200), until: end)
        let archived = try JSONEncoder().encode(style)
        let restored = try JSONDecoder().decode(SystemFormatStyle.Timer.self, from: archived)
        #expect(restored.format(end.addingTimeInterval(-1177)) == style.format(end.addingTimeInterval(-1177)))
    }
}

struct ManualLocationTests {
    private let london = ManualPrayerLocation(city: "London", detail: "England, United Kingdom",
                                             latitude: 51.5074, longitude: -0.1278,
                                             timeZoneIdentifier: "Europe/London")

    @Test func selectionPersistsCoordinatesNameAndTimeZone() throws {
        let data = try JSONEncoder().encode(london)
        let restored = try JSONDecoder().decode(ManualPrayerLocation.self, from: data)
        #expect(restored == london)
        #expect(SharedDefaults.timeZone(for: restored).identifier == "Europe/London")
        #expect(SharedDefaults.timeZone(for: nil) == TimeZone.current)
    }

    @Test func destinationTimeZoneObservesDaylightSaving() {
        let zone = SharedDefaults.timeZone(for: london)
        let winter = ISO8601DateFormatter().date(from: "2030-01-08T12:00:00Z")!
        let summer = ISO8601DateFormatter().date(from: "2030-07-08T12:00:00Z")!
        #expect(zone.secondsFromGMT(for: winter) == 0)
        #expect(zone.secondsFromGMT(for: summer) == 3600)
    }

    @Test func prayerCalculationUsesDestinationDayAcrossMidnight() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = SharedDefaults.timeZone(for: london)
        let instant = ISO8601DateFormatter().date(from: "2030-07-08T23:30:00Z")!
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: instant)!
        let location = CLLocation(latitude: london.latitude, longitude: london.longitude)
        let prayers = PrayerCalculationService.calculate(for: instant, location: location,
                                                          settings: PrayerSettings(), calendar: calendar)
        let noonPrayers = PrayerCalculationService.calculate(for: noon, location: location,
                                                              settings: PrayerSettings(), calendar: calendar)
        #expect(!prayers.isEmpty)
        #expect(prayers.map(\.time) == noonPrayers.map(\.time))
        #expect(calendar.component(.day, from: prayers.first { $0.name == .dhuhr }!.time) == 9)
    }

    @Test func notificationTriggerKeepsDestinationTimeZone() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = SharedDefaults.timeZone(for: london)
        let instant = ISO8601DateFormatter().date(from: "2030-07-08T12:15:00Z")!
        let components = NotificationScheduler.triggerComponents(for: instant, calendar: calendar)
        #expect(components.hour == 13)
        #expect(components.timeZone?.identifier == "Europe/London")
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        #expect(trigger.nextTriggerDate() == instant)
    }

    @Test func olderWatchPayloadCannotReplaceManualCity() throws {
        let name = "apta-location-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let data = try JSONEncoder().encode(london)
        SharedDefaults.storeLocationPayload([
            SharedDefaults.manualLocationKey: data,
            SharedDefaults.latitudeKey: london.latitude,
            SharedDefaults.longitudeKey: london.longitude,
            SharedDefaults.locationUpdatedAtKey: 200.0
        ], in: defaults)
        SharedDefaults.storeLocationPayload([
            SharedDefaults.manualLocationKey: Data(),
            SharedDefaults.latitudeKey: 40.7128,
            SharedDefaults.locationUpdatedAtKey: 100.0
        ], in: defaults)
        #expect(defaults.data(forKey: SharedDefaults.manualLocationKey) == data)
        #expect(defaults.double(forKey: SharedDefaults.latitudeKey) == london.latitude)
        SharedDefaults.storeLocationPayload([
            SharedDefaults.manualLocationKey: Data(),
            SharedDefaults.latitudeKey: 0.0,
            SharedDefaults.longitudeKey: 0.0,
            SharedDefaults.locationUpdatedAtKey: 300.0
        ], in: defaults)
        #expect(defaults.data(forKey: SharedDefaults.manualLocationKey) == Data())
        #expect(defaults.double(forKey: SharedDefaults.latitudeKey) == 0)
    }
}

struct NotificationPreviewTests {
    @Test func previewAndScheduledNotificationUseSameStyleMessages() {
        let date = Date(timeIntervalSince1970: 1_900_000_000)
        var settings = PrayerSettings()
        settings.notificationStyle = .simple
        #expect(NotificationMessages.prayerMessage(for: .dhuhr, time: date, date: date,
                                                   isRamadan: false, settings: settings)
                == NotificationMessages.simpleMessage(for: .dhuhr, time: date, settings: settings))
        settings.notificationStyle = .fun
        #expect(NotificationMessages.prayerMessage(for: .dhuhr, time: date, date: date,
                                                   isRamadan: false, settings: settings)
                == NotificationMessages.funMessage(for: .dhuhr, date: date, isRamadan: false))
        #expect(NotificationMessages.prayerMessage(for: .sunrise, time: date, date: date,
                                                   isRamadan: false, settings: settings)
                == NotificationMessages.funMessage(for: .sunrise, date: date, isRamadan: false))
    }

    @Test func everyWhimsyEventHasCopyWithoutFixedClockTimesOrEmDashes() {
        let date = Date(timeIntervalSince1970: 1_900_000_000)
        for prayer in [PrayerName.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha, .ishraq] {
            #expect(!NotificationMessages.funMessage(for: prayer, date: date, isRamadan: false).isEmpty)
        }
        let pools = [NotificationMessages.fajrMessages, NotificationMessages.sunriseMessages,
                     NotificationMessages.dhuhrMessages, NotificationMessages.asrMessages,
                     NotificationMessages.maghribMessages, NotificationMessages.ishaMessages,
                     NotificationMessages.ishraqMessages, NotificationMessages.ramadanFajrMessages,
                     NotificationMessages.iftarMessages]
        for message in pools.flatMap({ $0 }) {
            #expect(!message.contains("\u{2014}"))
            #expect(message.range(of: #"\d"#, options: .regularExpression) == nil)
        }
    }

    @Test func earlyRemindersKeepExactTimingInBothFormats() {
        let date = Date(timeIntervalSince1970: 1_900_000_000)
        for format in PrayerSettings.TimeFormat.allCases {
            for minutes in PrayerSettings.preNotificationOptions where minutes > 0 {
                for prayer in [PrayerName.fajr, .dhuhr, .asr, .maghrib, .isha] {
                    var settings = PrayerSettings()
                    settings.timeFormat = format
                    settings.notificationStyle = .simple
                    let standard = NotificationMessages.preMessage(for: prayer, minutes: minutes,
                                                                    time: date, settings: settings)
                    settings.notificationStyle = .fun
                    let whimsy = NotificationMessages.preMessage(for: prayer, minutes: minutes,
                                                                  time: date, settings: settings)
                    #expect(standard.hasPrefix("\(minutes) minutes until \(prayer.rawValue) at "))
                    #expect(whimsy.hasPrefix(standard + ". "))
                    #expect(whimsy.count > standard.count)
                }
            }
        }
    }

    @Test func ramadanFajrSeparatesAdvanceReminderFromFastBeginning() {
        let date = Date(timeIntervalSince1970: 1_900_000_000)
        for style in PrayerSettings.NotificationStyle.allCases {
            var settings = PrayerSettings()
            settings.notificationStyle = style
            let early = NotificationMessages.preMessage(for: .fajr, minutes: 15, time: date,
                                                         settings: settings, isRamadan: true)
            #expect(early.contains("15 minutes until Fajr"))
            #expect(early.contains("wrap up suhoor"))
            #expect(!early.contains("Suhoor has ended"))
            let atFajr = NotificationMessages.prayerMessage(for: .fajr, time: date, date: date,
                                                             isRamadan: true, settings: settings)
            #expect(atFajr.hasPrefix("Suhoor has ended."))
            let ordinary = NotificationMessages.prayerMessage(for: .fajr, time: date, date: date,
                                                               isRamadan: false, settings: settings)
            #expect(!ordinary.lowercased().contains("suhoor"))
        }
        for message in NotificationMessages.ramadanFajrMessages {
            #expect(message.hasPrefix("Suhoor has ended."))
            #expect(message.contains("Fajr"))
        }
    }

    @Test func boundaryAlertsStayPlainRegardlessOfStyle() {
        let date = Date(timeIntervalSince1970: 1_900_000_000)
        var settings = PrayerSettings()
        for label in ["ends", "best before"] {
            settings.notificationStyle = .simple
            let standard = NotificationMessages.boundaryMessage(label: label, prayer: .isha,
                                                                 time: date, settings: settings)
            settings.notificationStyle = .fun
            #expect(NotificationMessages.boundaryMessage(label: label, prayer: .isha,
                                                         time: date, settings: settings) == standard)
        }
    }

    @Test func dailyMessageSelectionIsStableAndRotates() {
        let calendar = SharedDefaults.prayerCalendar
        let date = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_900_000_000))
        let messages = (0..<NotificationMessages.sunriseMessages.count).map { offset in
            NotificationMessages.funMessage(for: .sunrise,
                                             date: calendar.date(byAdding: .day, value: offset, to: date)!,
                                             isRamadan: false)
        }
        #expect(Set(messages) == Set(NotificationMessages.sunriseMessages))
        #expect(messages.first == NotificationMessages.funMessage(for: .sunrise,
                                                                   date: date.addingTimeInterval(3600),
                                                                   isRamadan: false))
    }
}

struct PrayerWindowResolverTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    @Test func resolvesDaytimePrayerWindow() {
        let resolution = PrayerWindowResolver.resolve(
            at: date(day: 8, hour: 15, minute: 0),
            prayers: samplePrayers(),
            calendar: calendar
        )

        #expect(resolution.previousPrayer?.name == .dhuhr)
        #expect(resolution.currentPrayer?.name == .dhuhr)
        #expect(resolution.nextPrayer?.name == .asr)
        #expect(resolution.progressStartTime == date(day: 8, hour: 13, minute: 0))
        #expect(resolution.progressEndTime == date(day: 8, hour: 17, minute: 0))
        #expect(resolution.displayPrayers.map(\.name) == [.fajr, .dhuhr, .asr, .maghrib, .isha])
    }

    @Test func resolvesAfterIshaToNextDayFajr() {
        let resolution = PrayerWindowResolver.resolve(
            at: date(day: 9, hour: 1, minute: 0),
            prayers: samplePrayers(),
            calendar: calendar
        )

        #expect(resolution.previousPrayer?.name == .isha)
        #expect(resolution.currentPrayer?.name == .isha)
        #expect(resolution.previousPrayer?.time == date(day: 8, hour: 21, minute: 30))
        #expect(resolution.nextPrayer?.name == .fajr)
        #expect(resolution.nextPrayer?.time == date(day: 9, hour: 5, minute: 0))
        #expect(resolution.displayPrayers.first?.time == date(day: 9, hour: 5, minute: 0))
    }

    @Test func resolvesAfterFajrWithoutStaleIshaAnchor() {
        let resolution = PrayerWindowResolver.resolve(
            at: date(day: 9, hour: 6, minute: 0),
            prayers: samplePrayers(),
            calendar: calendar
        )

        #expect(resolution.previousPrayer?.name == .fajr)
        #expect(resolution.currentPrayer?.name == .fajr)
        #expect(resolution.previousPrayer?.time == date(day: 9, hour: 5, minute: 0))
        #expect(resolution.nextPrayer?.name == .dhuhr)
        #expect(resolution.nextPrayer?.time == date(day: 9, hour: 13, minute: 0))
        #expect(resolution.progressStartTime == date(day: 9, hour: 5, minute: 0))
    }

    @Test func resolvesAfterFajrToSunriseWhenIncluded() {
        let resolution = PrayerWindowResolver.resolve(
            at: date(day: 9, hour: 6, minute: 0),
            prayers: samplePrayers(includeSunrise: true),
            calendar: calendar
        )

        #expect(resolution.previousPrayer?.name == .fajr)
        #expect(resolution.currentPrayer?.name == .fajr)
        #expect(resolution.nextPrayer?.name == .sunrise)
        #expect(resolution.nextPrayer?.time == date(day: 9, hour: 6, minute: 30))
        #expect(resolution.progressEndTime == date(day: 9, hour: 6, minute: 30))
    }

    @Test func keepsSunriseAsTheCurrentEventUntilDhuhr() {
        let resolution = PrayerWindowResolver.resolve(
            at: date(day: 9, hour: 7, minute: 0),
            prayers: samplePrayers(includeSunrise: true),
            calendar: calendar
        )

        #expect(resolution.previousPrayer?.name == .sunrise)
        #expect(resolution.currentPrayer?.name == .sunrise)
        #expect(resolution.nextPrayer?.name == .dhuhr)
        #expect(resolution.progressStartTime == date(day: 9, hour: 6, minute: 30))
        #expect(resolution.progressEndTime == date(day: 9, hour: 13, minute: 0))
    }

    @Test func preservesIshraqWhenEnabled() {
        let resolution = PrayerWindowResolver.resolve(
            at: date(day: 8, hour: 5, minute: 30),
            prayers: samplePrayers(includeIshraq: true),
            calendar: calendar
        )

        #expect(resolution.previousPrayer?.name == .fajr)
        #expect(resolution.currentPrayer?.name == .fajr)
        #expect(resolution.nextPrayer?.name == .ishraq)
        #expect(resolution.nextPrayer?.time == date(day: 8, hour: 6, minute: 20))
    }

    private func samplePrayers(includeSunrise: Bool = false, includeIshraq: Bool = false) -> [PrayerTimeEntry] {
        var prayers = dayPrayers(day: 8, includeSunrise: includeSunrise, includeIshraq: includeIshraq)
        prayers.append(contentsOf: dayPrayers(day: 9, includeSunrise: includeSunrise, includeIshraq: includeIshraq))
        return prayers
    }

    private func dayPrayers(day: Int, includeSunrise: Bool, includeIshraq: Bool) -> [PrayerTimeEntry] {
        var prayers = [
            PrayerTimeEntry(name: .fajr, time: date(day: day, hour: 5, minute: 0)),
            PrayerTimeEntry(name: .dhuhr, time: date(day: day, hour: 13, minute: 0)),
            PrayerTimeEntry(name: .asr, time: date(day: day, hour: 17, minute: 0)),
            PrayerTimeEntry(name: .maghrib, time: date(day: day, hour: 20, minute: 0)),
            PrayerTimeEntry(name: .isha, time: date(day: day, hour: 21, minute: 30)),
        ]

        if includeSunrise {
            prayers.insert(
                PrayerTimeEntry(name: .sunrise, time: date(day: day, hour: 6, minute: 30)),
                at: 1
            )
        }

        if includeIshraq {
            prayers.insert(
                PrayerTimeEntry(name: .ishraq, time: date(day: day, hour: 6, minute: 20)),
                at: 1
            )
        }

        return prayers
    }

    private func date(day: Int, hour: Int, minute: Int) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: 2026,
                month: 4,
                day: day,
                hour: hour,
                minute: minute
            )
        )!
    }

}

struct HanbaliBoundaryTests {
    private let location = CLLocation(latitude: 40.7128, longitude: -74.0060)
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }()

    @Test func asrBoundaryMatchesHanafiAsr() {
        var settings = PrayerSettings()
        settings.calculationMethod = .northAmerica
        settings.asrMethod = .standard
        settings.showHanbaliBoundaries = true

        var hanafiSettings = settings
        hanafiSettings.asrMethod = .hanafi
        hanafiSettings.showHanbaliBoundaries = false

        let date = date(year: 2026, month: 4, day: 8)
        let entries = PrayerCalculationService.calculate(for: date, location: location, settings: settings)
        let hanafiEntries = PrayerCalculationService.calculate(for: date, location: location, settings: hanafiSettings)

        #expect(entries.first(where: { $0.name == .asr })?.supplementalTime?.label == "ends")
        #expect(entries.first(where: { $0.name == .asr })?.supplementalTime?.time == hanafiEntries.first(where: { $0.name == .asr })?.time)
    }

    @Test func ishaBoundaryUsesOneThirdOfNightFromMaghribToNextFajr() {
        var settings = PrayerSettings()
        settings.calculationMethod = .northAmerica
        settings.showHanbaliBoundaries = true

        var baseSettings = settings
        baseSettings.showHanbaliBoundaries = false

        let date = date(year: 2026, month: 4, day: 8)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!
        let entries = PrayerCalculationService.calculate(for: date, location: location, settings: settings)
        let baseEntries = PrayerCalculationService.calculate(for: date, location: location, settings: baseSettings)
        let tomorrowEntries = PrayerCalculationService.calculate(for: tomorrow, location: location, settings: baseSettings)

        let maghrib = baseEntries.first(where: { $0.name == .maghrib })!.time
        let nextFajr = tomorrowEntries.first(where: { $0.name == .fajr })!.time
        let expected = PrayerCalculationService.oneThirdOfNight(maghrib: maghrib, nextFajr: nextFajr)
        let actual = entries.first(where: { $0.name == .isha })?.supplementalTime

        #expect(actual?.label == "best before")
        #expect(abs((actual?.time.timeIntervalSince(expected) ?? .infinity)) < 0.001)
    }

    @Test func boundariesAreAbsentWhenDisabledAndOrderingIsUnchanged() {
        var settings = PrayerSettings()
        settings.calculationMethod = .northAmerica
        settings.showHanbaliBoundaries = false

        let entries = PrayerCalculationService.calculate(
            for: date(year: 2026, month: 4, day: 8),
            location: location,
            settings: settings
        )

        #expect(entries.allSatisfy { $0.supplementalTime == nil })
        #expect(entries.map(\.name) == [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha])
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        calendar.date(
            from: DateComponents(
                timeZone: calendar.timeZone,
                year: year,
                month: month,
                day: day
            )
        )!
    }
}

struct PrayerCountdownFormatterTests {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    @Test func roundsUpToWholeMinutesWithoutShowingSeconds() {
        #expect(text(seconds: 61) == "2 min left")
        #expect(text(seconds: 60) == "1 min left")
        #expect(text(seconds: 59) == "1 min left")
        #expect(text(seconds: 1) == "1 min left")
    }

    @Test func formatsHoursCompactly() {
        #expect(text(seconds: 60 * 60) == "1h left")
        #expect(text(seconds: 61 * 60) == "1h 1m left")
    }

    @Test func reachesNowAtTheBoundary() {
        #expect(text(seconds: 0) == "now")
        #expect(text(seconds: -1) == "now")
    }

    private func text(seconds: TimeInterval) -> String {
        PrayerCountdownFormatter.remainingMinutes(
            until: now.addingTimeInterval(seconds),
            from: now
        )
    }
}

struct ProStatusResolverTests {
    @Test func newerContextUnlocksAStaleStoredValue() {
        let result = ProStatusResolver.resolve(
            storedValue: false,
            storedUpdatedAt: 100,
            contextValue: true,
            contextUpdatedAt: 200
        )
        #expect(result)
    }

    @Test func newerContextCanRevokeAStoredEntitlement() {
        let result = ProStatusResolver.resolve(
            storedValue: true,
            storedUpdatedAt: 100,
            contextValue: false,
            contextUpdatedAt: 200
        )
        #expect(!result)
    }

    @Test func staleContextCannotOverrideNewerStoredState() {
        let result = ProStatusResolver.resolve(
            storedValue: true,
            storedUpdatedAt: 200,
            contextValue: false,
            contextUpdatedAt: 100
        )
        #expect(result)
    }

    @Test func storedStateWinsWhenThereIsNoContext() {
        let result = ProStatusResolver.resolve(
            storedValue: true,
            storedUpdatedAt: 200,
            contextValue: nil,
            contextUpdatedAt: nil
        )
        #expect(result)
    }
}

struct LocationLabelFormatterTests {
    @Test func prefersCityOverState() {
        let label = LocationLabelFormatter.city(
            locality: "Buffalo",
            subAdministrativeArea: "Erie County",
            administrativeArea: "NY",
            country: "United States"
        )
        #expect(label == "Buffalo")
    }

    @Test func fallsBackWithoutReturningBlankText() {
        #expect(LocationLabelFormatter.city(
            locality: "  ",
            subAdministrativeArea: "Erie County",
            administrativeArea: "NY",
            country: "United States"
        ) == "Erie County")

        #expect(LocationLabelFormatter.city(
            locality: nil,
            subAdministrativeArea: nil,
            administrativeArea: nil,
            country: nil
        ) == "Current Location")
    }
}

struct LocationUpdatePolicyTests {
    private let now = Date(timeIntervalSince1970: 10_000)

    @Test func acceptsARecentAccurateNewerLocation() {
        let candidate = location(timestamp: 9_900, accuracy: 1_000)
        #expect(LocationUpdatePolicy.shouldAccept(
            candidate,
            lastAcceptedTimestamp: 9_000,
            now: now
        ))
    }

    @Test func rejectsOutdatedDuplicateOrVeryInaccurateLocations() {
        #expect(!LocationUpdatePolicy.shouldAccept(
            location(timestamp: 2_000, accuracy: 1_000),
            lastAcceptedTimestamp: 1_000,
            now: now
        ))
        #expect(!LocationUpdatePolicy.shouldAccept(
            location(timestamp: 9_000, accuracy: 1_000),
            lastAcceptedTimestamp: 9_000,
            now: now
        ))
        #expect(!LocationUpdatePolicy.shouldAccept(
            location(timestamp: 9_900, accuracy: 25_000),
            lastAcceptedTimestamp: 9_000,
            now: now
        ))
    }

    private func location(timestamp: TimeInterval, accuracy: CLLocationAccuracy) -> CLLocation {
        CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 42.8864, longitude: -78.8784),
            altitude: 0,
            horizontalAccuracy: accuracy,
            verticalAccuracy: 10,
            timestamp: Date(timeIntervalSince1970: timestamp)
        )
    }
}

struct LocationUpgradePromptPolicyTests {
    @Test func offersOnlyOnceToExistingWhenInUseUsers() {
        #expect(LocationUpgradePromptPolicy.shouldOffer(
            hasCompletedOnboarding: true,
            hasMadeChoice: false,
            authorizationStatus: .authorizedWhenInUse
        ))
        #expect(!LocationUpgradePromptPolicy.shouldOffer(
            hasCompletedOnboarding: false,
            hasMadeChoice: false,
            authorizationStatus: .authorizedWhenInUse
        ))
        #expect(!LocationUpgradePromptPolicy.shouldOffer(
            hasCompletedOnboarding: true,
            hasMadeChoice: true,
            authorizationStatus: .authorizedWhenInUse
        ))
        #expect(!LocationUpgradePromptPolicy.shouldOffer(
            hasCompletedOnboarding: true,
            hasMadeChoice: false,
            authorizationStatus: .authorizedAlways
        ))
    }
}
