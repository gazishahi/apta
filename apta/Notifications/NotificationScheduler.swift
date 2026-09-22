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
        let calendar = SharedDefaults.prayerCalendar

        for dayOffset in 0..<3 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            let prayers = PrayerCalculationService.calculate(for: date, location: location, settings: settings)
            let isRamadan = settings.ramadanNotificationsEnabled && Self.isRamadan(on: date, hijriAdjustment: settings.hijriAdjustment)

            for entry in prayers {
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

                let body = NotificationMessages.prayerMessage(for: entry.name, time: entry.time,
                                                               date: date, isRamadan: isRamadan,
                                                               settings: settings)

                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default

                let comps = triggerComponents(for: entry.time, calendar: calendar)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

                guard let year = comps.year, let month = comps.month, let day = comps.day else { return }
                let id = "\(entry.name.rawValue)-\(year)-\(month)-\(day)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request)

                // Early reminder ("15 minutes until Fajr"), skipped for
                // informational times that aren't prayers to head to.
                if settings.preNotificationMinutes > 0,
                   entry.name != .sunrise, entry.name != .ishraq {
                    let preTime = entry.time.addingTimeInterval(TimeInterval(-settings.preNotificationMinutes * 60))
                    if preTime > now {
                        let preContent = UNMutableNotificationContent()
                        preContent.title = title
                        preContent.body = NotificationMessages.preMessage(
                            for: entry.name,
                            minutes: settings.preNotificationMinutes,
                            time: entry.time,
                            settings: settings,
                            isRamadan: isRamadan
                        )
                        preContent.sound = .default

                        let preComps = triggerComponents(for: preTime, calendar: calendar)
                        let preTrigger = UNCalendarNotificationTrigger(dateMatching: preComps, repeats: false)
                        let preId = "\(entry.name.rawValue)-pre-\(year)-\(month)-\(day)"
                        center.add(UNNotificationRequest(identifier: preId, content: preContent, trigger: preTrigger))
                    }
                }
            }

            if settings.showHanbaliBoundaries && settings.boundaryNotificationsEnabled {
                for entry in prayers {
                    guard let supplemental = entry.supplementalTime else { continue }
                    guard supplemental.time > now else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = entry.name.rawValue
                    content.body = NotificationMessages.boundaryMessage(
                        label: supplemental.label,
                        prayer: entry.name,
                        time: supplemental.time,
                        settings: settings
                    )
                    content.sound = .default

                    let comps = triggerComponents(for: supplemental.time, calendar: calendar)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

                    guard let year = comps.year, let month = comps.month, let day = comps.day else { continue }
                    let id = "\(entry.name.rawValue)-boundary-\(year)-\(month)-\(day)"
                    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                    center.add(request)
                }
            }
        }
    }

    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func triggerComponents(for date: Date, calendar: Calendar = SharedDefaults.prayerCalendar) -> DateComponents {
        calendar.dateComponents([.timeZone, .year, .month, .day, .hour, .minute, .second], from: date)
    }

    // MARK: - Ramadan Detection

    static func isRamadan(on date: Date, hijriAdjustment: Int) -> Bool {
        let adjusted = SharedDefaults.prayerCalendar.date(byAdding: .day, value: hijriAdjustment, to: date) ?? date
        let islamicCalendar = SharedDefaults.calendar(identifier: .islamicUmmAlQura)
        let month = islamicCalendar.component(.month, from: adjusted)
        return month == 9
    }
}
