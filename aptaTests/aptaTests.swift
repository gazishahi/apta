//
//  aptaTests.swift
//  aptaTests
//
//  Created by Gazi Shahi on 3/3/26.
//

import Foundation
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

    private func samplePrayers(includeIshraq: Bool = false) -> [PrayerTimeEntry] {
        var prayers = dayPrayers(day: 8, includeIshraq: includeIshraq)
        prayers.append(contentsOf: dayPrayers(day: 9, includeIshraq: includeIshraq))
        return prayers
    }

    private func dayPrayers(day: Int, includeIshraq: Bool) -> [PrayerTimeEntry] {
        var prayers = [
            PrayerTimeEntry(name: .fajr, time: date(day: day, hour: 5, minute: 0)),
            PrayerTimeEntry(name: .dhuhr, time: date(day: day, hour: 13, minute: 0)),
            PrayerTimeEntry(name: .asr, time: date(day: day, hour: 17, minute: 0)),
            PrayerTimeEntry(name: .maghrib, time: date(day: day, hour: 20, minute: 0)),
            PrayerTimeEntry(name: .isha, time: date(day: day, hour: 21, minute: 30)),
        ]

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
