import Foundation
import Adhan
import CoreLocation

struct PrayerCalculationService {
    private static func buildParameters(from settings: PrayerSettings) -> CalculationParameters {
        var params = settings.calculationMethod.adhanMethod.params
        params.madhab = settings.asrMethod.madhab
        params.highLatitudeRule = settings.highLatitudeRule.adhanRule
        if let fajrAngle = settings.customFajrAngle {
            params.fajrAngle = fajrAngle
        }
        if let ishaAngle = settings.customIshaAngle {
            params.ishaAngle = ishaAngle
        }
        return params
    }

    static func calculate(for date: Date = Date(), location: CLLocation, settings: PrayerSettings) -> [PrayerTimeEntry] {
        let coordinates = Coordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        let params = buildParameters(from: settings)
        let cal = Calendar(identifier: .gregorian)
        let components = cal.dateComponents([.year, .month, .day], from: date)

        guard let prayers = PrayerTimes(coordinates: coordinates, date: components, calculationParameters: params) else {
            return []
        }

        var entries: [PrayerTimeEntry] = [
            PrayerTimeEntry(name: .fajr, time: prayers.fajr),
            PrayerTimeEntry(name: .sunrise, time: prayers.sunrise),
        ]
        if settings.showIshraq {
            let ishraqTime = Calendar.current.date(byAdding: .minute, value: 15, to: prayers.sunrise) ?? prayers.sunrise
            entries.append(PrayerTimeEntry(name: .ishraq, time: ishraqTime))
        }
        entries.append(contentsOf: [
            PrayerTimeEntry(name: .dhuhr, time: prayers.dhuhr),
            PrayerTimeEntry(name: .asr, time: prayers.asr),
            PrayerTimeEntry(name: .maghrib, time: prayers.maghrib),
            PrayerTimeEntry(name: .isha, time: prayers.isha),
        ])

        return entries
    }

    static func currentPrayer(location: CLLocation, settings: PrayerSettings) -> Prayer? {
        let coordinates = Coordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        let params = buildParameters(from: settings)
        let cal = Calendar(identifier: .gregorian)
        let components = cal.dateComponents([.year, .month, .day], from: Date())

        guard let prayers = PrayerTimes(coordinates: coordinates, date: components, calculationParameters: params) else {
            return nil
        }

        return prayers.currentPrayer()
    }
}

struct PrayerWindowResolution {
    let previousPrayer: PrayerTimeEntry?
    let nextPrayer: PrayerTimeEntry?
    let displayPrayers: [PrayerTimeEntry]

    var currentPrayer: PrayerTimeEntry? { previousPrayer }
    var progressStartTime: Date? { previousPrayer?.time }
    var progressEndTime: Date? { nextPrayer?.time }
}

enum PrayerWindowResolver {
    static func resolve(
        at date: Date,
        prayers: [PrayerTimeEntry],
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> PrayerWindowResolution {
        let sortedPrayers = prayers.sorted { $0.time < $1.time }
        let previousPrayer = sortedPrayers.last(where: { $0.time <= date })
        let nextPrayer = sortedPrayers.first(where: { $0.time > date })

        let prayersByDay = Dictionary(grouping: sortedPrayers) { calendar.startOfDay(for: $0.time) }
        let currentDay = calendar.startOfDay(for: date)
        let currentDayPrayers = (prayersByDay[currentDay] ?? []).sorted { $0.time < $1.time }
        let hasRemainingPrayerToday = currentDayPrayers.contains(where: { $0.time > date })

        let displayDay: Date
        if hasRemainingPrayerToday || nextPrayer == nil {
            displayDay = currentDay
        } else if let nextPrayer {
            displayDay = calendar.startOfDay(for: nextPrayer.time)
        } else {
            displayDay = currentDay
        }

        let displayPrayers = (prayersByDay[displayDay] ?? []).sorted { $0.time < $1.time }

        return PrayerWindowResolution(
            previousPrayer: previousPrayer,
            nextPrayer: nextPrayer,
            displayPrayers: displayPrayers
        )
    }
}
