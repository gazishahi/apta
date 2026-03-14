import Foundation
import UserNotifications
import CoreLocation

enum NotificationScheduler {

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func scheduleUpcoming(location: CLLocation?) {
        let settings = PrayerSettings.current
        guard settings.notificationsEnabled, let location else { return }

        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let now = Date()
        let calendar = Calendar(identifier: .gregorian)

        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            let prayers = PrayerCalculationService.calculate(for: date, location: location, settings: settings)
            let isRamadan = settings.ramadanNotificationsEnabled && Self.isRamadan(on: date, hijriAdjustment: settings.hijriAdjustment)

            for entry in prayers {
                guard entry.name != .sunrise else { continue }
                guard entry.time > now else { continue }
                guard settings.isNotificationEnabled(for: entry.name) else { continue }

                let title: String
                if isRamadan && entry.name == .fajr {
                    title = "Suhoor / Fajr"
                } else if isRamadan && entry.name == .maghrib {
                    title = "Iftar / Maghrib"
                } else {
                    title = entry.name.rawValue
                }

                let body: String
                switch settings.notificationStyle {
                case .fun:
                    body = NotificationMessages.funMessage(for: entry.name, date: date, isRamadan: isRamadan)
                case .simple:
                    body = NotificationMessages.simpleMessage(for: entry.name, time: entry.time, settings: settings)
                }

                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default

                let comps = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: entry.time)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

                guard let year = comps.year, let month = comps.month, let day = comps.day else { return }
                let id = "\(entry.name.rawValue)-\(year)-\(month)-\(day)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request)
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - Ramadan Detection

    static func isRamadan(on date: Date, hijriAdjustment: Int) -> Bool {
        let adjusted = Calendar.current.date(byAdding: .day, value: hijriAdjustment, to: date) ?? date
        let islamicCalendar = Calendar(identifier: .islamicUmmAlQura)
        let month = islamicCalendar.component(.month, from: adjusted)
        return month == 9
    }
}
