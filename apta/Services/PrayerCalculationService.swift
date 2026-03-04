import Foundation
import Adhan
import CoreLocation

struct PrayerCalculationService {
    static func calculate(for date: Date = Date(), location: CLLocation, settings: PrayerSettings) -> [PrayerTimeEntry] {
        let coordinates = Coordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        var params = settings.calculationMethod.adhanMethod.params
        params.madhab = settings.asrMethod.madhab
        params.highLatitudeRule = settings.highLatitudeRule.adhanRule

        let cal = Calendar(identifier: .gregorian)
        let components = cal.dateComponents([.year, .month, .day], from: date)

        guard let prayers = PrayerTimes(coordinates: coordinates, date: components, calculationParameters: params) else {
            return []
        }

        return [
            PrayerTimeEntry(name: .fajr, time: prayers.fajr),
            PrayerTimeEntry(name: .sunrise, time: prayers.sunrise),
            PrayerTimeEntry(name: .dhuhr, time: prayers.dhuhr),
            PrayerTimeEntry(name: .asr, time: prayers.asr),
            PrayerTimeEntry(name: .maghrib, time: prayers.maghrib),
            PrayerTimeEntry(name: .isha, time: prayers.isha),
        ]
    }

    static func currentPrayer(location: CLLocation, settings: PrayerSettings) -> Prayer? {
        let coordinates = Coordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        var params = settings.calculationMethod.adhanMethod.params
        params.madhab = settings.asrMethod.madhab
        params.highLatitudeRule = settings.highLatitudeRule.adhanRule

        let cal = Calendar(identifier: .gregorian)
        let components = cal.dateComponents([.year, .month, .day], from: Date())

        guard let prayers = PrayerTimes(coordinates: coordinates, date: components, calculationParameters: params) else {
            return nil
        }

        return prayers.currentPrayer()
    }
}
