//
//  aptaTests.swift
//  aptaTests
//
//  Created by Gazi Shahi on 3/3/26.
//

import Foundation
import CoreLocation
import Testing
@testable import apta

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
