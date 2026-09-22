//
//  AptaWatch_Watch_AppTests.swift
//  AptaWatch Watch AppTests
//
//  Created by Gazi Shahi on 3/16/26.
//

import Testing
import Foundation
import SwiftUI
@testable import AptaWatch_Watch_App

struct AptaWatch_Watch_AppTests {

    @Test func systemCountdownAdvancesWithoutRebuildingItsStyle() throws {
        let end = Date(timeIntervalSince1970: 2_000_000_000)
        let style = PrayerCountdownStyle.timer(from: end.addingTimeInterval(-3600), until: end)
            .locale(Locale(identifier: "en_US"))
        let firstScreenshot = end.addingTimeInterval(-1894)
        let secondScreenshot = end.addingTimeInterval(-1177)
        #expect(String(style.format(firstScreenshot).characters) == "31 minutes")
        #expect(String(style.format(secondScreenshot).characters) == "19 minutes")
        let nextUpdate = try #require(style.discreteInput(after: secondScreenshot))
        #expect(nextUpdate > secondScreenshot)
        #expect(nextUpdate.timeIntervalSince(secondScreenshot) <= 60)
    }

    @Test func expiredCountdownNeverCountsUpOnWatch() {
        let end = Date(timeIntervalSince1970: 2_000_000_000)
        for minutesOnly in [true, false] {
            let style = PrayerCountdownStyle.timer(from: end.addingTimeInterval(-3600), until: end,
                                                   minutesOnly: minutesOnly)
            #expect(style.format(end) == style.format(end.addingTimeInterval(600)))
        }
    }

    @Test func minuteCountdownOmitsSecondsOnWatch() {
        let end = Date(timeIntervalSince1970: 2_000_000_000)
        let style = PrayerCountdownStyle.timer(from: end.addingTimeInterval(-7200), until: end)
            .locale(Locale(identifier: "en_US"))
        #expect(String(style.format(end.addingTimeInterval(-3780)).characters) == "1 hour, 3 minutes")
        #expect(String(style.format(end.addingTimeInterval(-59)).characters) == "0 minutes")
    }

}
