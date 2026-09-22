import Foundation
import Combine
import CoreLocation
import Adhan
import SwiftUI

class WatchPrayerViewModel: ObservableObject {
    @Published var nextPrayer: PrayerTimeEntry?
    @Published private(set) var countdownStart = Date()
    @Published var upcomingPrayers: [PrayerTimeEntry] = []
    @Published var qiblaDirection: Double = 0
    @Published var hijriDate: String = ""
    @Published var isProUser: Bool = false
    @Published var backgroundPreset: BackgroundPreset? = nil

    func clearPrayers() {
        nextPrayer = nil
        upcomingPrayers = []
    }

    func calculate(location: CLLocation) {
        SharedDefaults.suite.synchronize()
        isProUser = SharedDefaults.isProUser
        backgroundPreset = BackgroundTheme.current.preset
        let settings = PrayerSettings.current
        let now = Date()
        countdownStart = now

        let todayPrayers = PrayerCalculationService.calculate(for: now, location: location, settings: settings)
            .filter { $0.name != .ishraq }
        let upcomingToday = todayPrayers.filter { $0.time > now }

        let maxRemaining = 5

        if upcomingToday.isEmpty {
            // All of today's prayers have passed — roll fully into tomorrow
            let tomorrow = SharedDefaults.prayerCalendar.date(byAdding: .day, value: 1, to: now)!
            let tomorrowPrayers = tomorrowPrayers(for: tomorrow, location: location, settings: settings)
            nextPrayer = tomorrowPrayers.first
            upcomingPrayers = Array(tomorrowPrayers.dropFirst().prefix(maxRemaining))
        } else {
            nextPrayer = upcomingToday.first
            var remaining = Array(upcomingToday.dropFirst())
            if remaining.count < maxRemaining {
                // Pad with the start of tomorrow to always fill the list
                let tomorrow = SharedDefaults.prayerCalendar.date(byAdding: .day, value: 1, to: now)!
                let needed = maxRemaining - remaining.count
                remaining.append(contentsOf: tomorrowPrayers(for: tomorrow, location: location, settings: settings).prefix(needed))
            }
            upcomingPrayers = Array(remaining.prefix(maxRemaining))
        }

        let coords = Coordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        qiblaDirection = Qibla(coordinates: coords).direction

        hijriDate = formatHijriDate(settings: settings)
    }

    private func tomorrowPrayers(for date: Date, location: CLLocation, settings: PrayerSettings) -> [PrayerTimeEntry] {
        PrayerCalculationService.calculate(for: date, location: location, settings: settings)
            .filter { $0.name != .ishraq }
    }

    private func formatHijriDate(settings: PrayerSettings) -> String {
        let calendar = SharedDefaults.calendar(identifier: .islamicUmmAlQura)
        let date = SharedDefaults.prayerCalendar.date(byAdding: .day, value: settings.hijriAdjustment, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.timeZone = SharedDefaults.prayerTimeZone
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}
