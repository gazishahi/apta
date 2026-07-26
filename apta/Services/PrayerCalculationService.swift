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
        let boundaries = settings.showHanbaliBoundaries
            ? hanbaliBoundaries(for: date, coordinates: coordinates, settings: settings, calendar: cal)
            : nil

        entries.append(contentsOf: [
            PrayerTimeEntry(name: .dhuhr, time: prayers.dhuhr),
            PrayerTimeEntry(
                name: .asr,
                time: prayers.asr,
                supplementalTime: boundaries?.endOfAsr.map {
                    PrayerSupplementalTime(label: "ends", time: $0)
                }
            ),
            PrayerTimeEntry(name: .maghrib, time: prayers.maghrib),
            PrayerTimeEntry(
                name: .isha,
                time: prayers.isha,
                supplementalTime: boundaries?.oneThirdNight.map {
                    PrayerSupplementalTime(label: "best before", time: $0)
                }
            ),
        ])

        return entries
    }

    static func oneThirdOfNight(maghrib: Date, nextFajr: Date) -> Date {
        maghrib.addingTimeInterval(nextFajr.timeIntervalSince(maghrib) / 3)
    }

    private static func hanbaliBoundaries(
        for date: Date,
        coordinates: Coordinates,
        settings: PrayerSettings,
        calendar: Calendar
    ) -> (endOfAsr: Date?, oneThirdNight: Date?) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let standardPrayers = PrayerTimes(
            coordinates: coordinates,
            date: components,
            calculationParameters: buildParameters(from: settings)
        ) else {
            return (nil, nil)
        }

        var hanafiParams = buildParameters(from: settings)
        hanafiParams.madhab = .hanafi
        let hanafiPrayers = PrayerTimes(
            coordinates: coordinates,
            date: components,
            calculationParameters: hanafiParams
        )

        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) else {
            return (hanafiPrayers?.asr, nil)
        }
        let tomorrowComponents = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        let tomorrowPrayers = PrayerTimes(
            coordinates: coordinates,
            date: tomorrowComponents,
            calculationParameters: buildParameters(from: settings)
        )

        let oneThirdNight = tomorrowPrayers.map {
            oneThirdOfNight(maghrib: standardPrayers.maghrib, nextFajr: $0.fajr)
        }

        return (hanafiPrayers?.asr, oneThirdNight)
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
