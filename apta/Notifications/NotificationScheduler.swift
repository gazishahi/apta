import Foundation
import UserNotifications
import CoreLocation
import UIKit

enum NotificationScheduler {
    private static let queue = NotificationQueueCoordinator(store: SystemNotificationStore())

    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    @discardableResult
    static func scheduleUpcoming(location: CLLocation?) -> Task<Bool, Never> {
        NotificationBackgroundRefresh.scheduleNext()
        let update = queue.enqueue(location: location, settings: PrayerSettings.current,
                                   calendar: SharedDefaults.prayerCalendar)
        if UIApplication.shared.applicationState != .background {
            let lease = UIApplication.shared.beginBackgroundTask(withName: "Schedule prayer notifications") {
                update.cancel()
            }
            Task { @MainActor in
                _ = await update.value
                if lease != .invalid { UIApplication.shared.endBackgroundTask(lease) }
            }
        }
        return update
    }

    static func savedLocation(in defaults: UserDefaults = SharedDefaults.suite) -> CLLocation? {
        if let data = defaults.data(forKey: SharedDefaults.manualLocationKey),
           let manual = try? JSONDecoder().decode(ManualPrayerLocation.self, from: data) {
            return CLLocation(latitude: manual.latitude, longitude: manual.longitude)
        }
        guard defaults.object(forKey: SharedDefaults.latitudeKey) != nil,
              defaults.object(forKey: SharedDefaults.longitudeKey) != nil else { return nil }
        return CLLocation(latitude: defaults.double(forKey: SharedDefaults.latitudeKey),
                          longitude: defaults.double(forKey: SharedDefaults.longitudeKey))
    }

    static func cancelAll() {
        queue.cancelPending()
        NotificationBackgroundRefresh.scheduleNext()
    }

    static func triggerComponents(for date: Date, calendar: Calendar = SharedDefaults.prayerCalendar) -> DateComponents {
        calendar.dateComponents([.timeZone, .year, .month, .day, .hour, .minute, .second], from: date)
    }

    static func isRamadan(on date: Date, hijriAdjustment: Int) -> Bool {
        let adjusted = SharedDefaults.prayerCalendar.date(byAdding: .day, value: hijriAdjustment, to: date) ?? date
        let islamicCalendar = SharedDefaults.calendar(identifier: .islamicUmmAlQura)
        return islamicCalendar.component(.month, from: adjusted) == 9
    }
}

/// Pure planning, independent of GPS authorization and the system queue.
enum PrayerNotificationPlan {
    // Leave headroom beneath the platform's historical 64-request ceiling.
    static let capacity = 60
    static let horizonDays = 30

    static func owns(_ identifier: String) -> Bool {
        identifier.range(of: #"^(Fajr|Sunrise|Dhuhr|Asr|Maghrib|Isha|Ishraq)(-pre|-boundary)?-\d{4}-\d{1,2}-\d{1,2}$"#,
                         options: .regularExpression) != nil
    }

    static func hasEnabledAlerts(_ settings: PrayerSettings) -> Bool {
        PrayerName.allCases.contains { name in
            settings.isNotificationEnabled(for: name) && (name != .ishraq || settings.showIshraq)
        } || (settings.showHanbaliBoundaries && settings.boundaryNotificationsEnabled)
    }

    static func requests(location: CLLocation, settings: PrayerSettings, now: Date,
                         calendar: Calendar, limit: Int = capacity) -> [UNNotificationRequest] {
        guard settings.notificationsEnabled, limit > 0 else { return [] }
        var candidates: [(time: Date, request: UNNotificationRequest)] = []
        for dayOffset in 0..<horizonDays {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }

            let prayers = PrayerCalculationService.calculate(for: date, location: location, settings: settings, calendar: calendar)
            let isRamadan = settings.ramadanNotificationsEnabled && NotificationScheduler.isRamadan(on: date, hijriAdjustment: settings.hijriAdjustment)

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

                let comps = NotificationScheduler.triggerComponents(for: entry.time, calendar: calendar)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

                guard let year = comps.year, let month = comps.month, let day = comps.day else { continue }
                let id = "\(entry.name.rawValue)-\(year)-\(month)-\(day)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                candidates.append((entry.time, request))

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

                        let preComps = NotificationScheduler.triggerComponents(for: preTime, calendar: calendar)
                        let preTrigger = UNCalendarNotificationTrigger(dateMatching: preComps, repeats: false)
                        let preId = "\(entry.name.rawValue)-pre-\(year)-\(month)-\(day)"
                        candidates.append((preTime, UNNotificationRequest(identifier: preId, content: preContent, trigger: preTrigger)))
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

                    let comps = NotificationScheduler.triggerComponents(for: supplemental.time, calendar: calendar)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

                    guard let year = comps.year, let month = comps.month, let day = comps.day else { continue }
                    let id = "\(entry.name.rawValue)-boundary-\(year)-\(month)-\(day)"
                    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                    candidates.append((supplemental.time, request))
                }
            }
        }
        // Sort all event types together before capping, so late reminders do
        // not crowd out an earlier prayer on the last scheduled day.
        let selected = candidates.sorted {
            $0.time == $1.time ? $0.request.identifier < $1.request.identifier : $0.time < $1.time
        }.prefix(min(limit, capacity)).map(\.request)
        let selectedIDs = Set(selected.map(\.identifier))
        return selected.filter { request in
            // Do not end the queue with an early reminder whose actual prayer
            // alert was cut off by the capacity limit.
            !request.identifier.contains("-pre-") ||
                selectedIDs.contains(request.identifier.replacingOccurrences(of: "-pre-", with: "-"))
        }
    }
}
