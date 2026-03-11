import Foundation
import Combine
import CoreLocation
import Adhan

@MainActor
class PrayerTimesViewModel: ObservableObject {
    @Published var currentPrayer: PrayerTimeEntry?
    @Published var upcomingPrayers: [PrayerTimeEntry] = []
    @Published var countdown: String = ""
    @Published var allPrayers: [PrayerTimeEntry] = []
    @Published var hijriDateString: String = ""
    @Published var sunriseTime: Date?
    @Published var sunsetTime: Date?
    @Published var qiblaDirection: Double = 0

    private var timer: Timer?
    private var locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
    }

    func start() {
        recalculate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func recalculate() {
        guard let location = locationService.location else { return }
        let settings = PrayerSettings.current

        allPrayers = PrayerCalculationService.calculate(location: location, settings: settings)

        // Cache sunrise/sunset for auto theme
        sunriseTime = allPrayers.first(where: { $0.name == .sunrise })?.time
        sunsetTime = allPrayers.first(where: { $0.name == .maghrib })?.time

        // Qibla direction
        let coordinates = Coordinates(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        qiblaDirection = Qibla(coordinates: coordinates).direction

        updateHijriDate()
        updateCurrentAndUpcoming()
    }

    private func updateHijriDate() {
        hijriDateString = hijriDateString(for: Date())
    }

    func hijriDateString(for date: Date) -> String {
        let settings = PrayerSettings.current
        let calendar = Calendar(identifier: .islamicUmmAlQura)
        let adjusted = Calendar.current.date(byAdding: .day, value: settings.hijriAdjustment, to: date) ?? date

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en")
        // "15 Ramadan 1447"
        formatter.dateFormat = "d MMMM y"

        return formatter.string(from: adjusted)
    }

    func prayers(for date: Date) -> [PrayerTimeEntry] {
        guard let location = locationService.location else { return [] }
        let settings = PrayerSettings.current
        return PrayerCalculationService.calculate(for: date, location: location, settings: settings)
    }

    private func updateCurrentAndUpcoming() {
        let now = Date()

        let upcoming = allPrayers.filter { $0.time > now }

        if upcoming.isEmpty {
            guard let location = locationService.location else { return }
            let settings = PrayerSettings.current
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
            let tomorrowPrayers = PrayerCalculationService.calculate(for: tomorrow, location: location, settings: settings)

            self.currentPrayer = allPrayers.last
            self.upcomingPrayers = Array(tomorrowPrayers.prefix(5))
        } else {
            let nextPrayer = upcoming.first!
            self.currentPrayer = nextPrayer

            var rest = Array(upcoming.dropFirst())
            if rest.count < 5 {
                guard let location = locationService.location else { return }
                let settings = PrayerSettings.current
                let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
                let tomorrowPrayers = PrayerCalculationService.calculate(for: tomorrow, location: location, settings: settings)
                let needed = 5 - rest.count
                rest.append(contentsOf: tomorrowPrayers.prefix(needed))
            }
            self.upcomingPrayers = Array(rest.prefix(5))
        }

        updateCountdown()
    }

    private func tick() {
        updateCurrentAndUpcoming()
    }

    private func updateCountdown() {
        guard let current = currentPrayer else {
            countdown = ""
            return
        }

        let now = Date()
        let diff = current.time.timeIntervalSince(now)

        if diff <= 0 {
            countdown = "now"
            return
        }

        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        let seconds = Int(diff) % 60

        if hours > 0 {
            countdown = "in \(hours)h \(minutes)m"
        } else if minutes > 0 {
            countdown = "in \(minutes)m \(seconds)s"
        } else {
            countdown = "in \(seconds)s"
        }
    }
}
