import CoreLocation
import Foundation
import OSLog
import UserNotifications

extension UNNotificationRequest {
    var prayerFireDate: Date? {
        (trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
    }
}

@MainActor
protocol NotificationStore {
    func authorizationStatus() async -> UNAuthorizationStatus
    func pendingRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func remove(identifiers: [String])
}

@MainActor
struct SystemNotificationStore: NotificationStore {
    private let center = UNUserNotificationCenter.current()
    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }
    func pendingRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }
    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }
    func remove(identifiers: [String]) { center.removePendingNotificationRequests(withIdentifiers: identifiers) }
}

/// Serializes foreground, settings, travel, and background updates. A newer
/// request supersedes unfinished updates. Explicit cancellation is a barrier.
@MainActor
final class NotificationQueueCoordinator {
    private let store: any NotificationStore
    private let defaults: UserDefaults
    private let logger = Logger(subsystem: "Gazi.apta", category: "Notifications")
    private var generation = 0
    private var tail: Task<Bool, Never>?

    init(store: any NotificationStore, defaults: UserDefaults = .standard) {
        self.store = store
        self.defaults = defaults
    }

    @discardableResult
    func enqueue(location: CLLocation?, settings: PrayerSettings, calendar: Calendar,
                 now: Date = Date()) -> Task<Bool, Never> {
        generation &+= 1
        let token = generation
        let previous = tail
        let task = Task { @MainActor in
            _ = await previous?.value
            guard self.isCurrent(token) else { return false }
            return await self.reconcile(location: location, settings: settings, calendar: calendar,
                                        now: now, token: token)
        }
        tail = task
        return task
    }

    @discardableResult
    func cancelPending() -> Task<Bool, Never> {
        generation &+= 1
        let previous = tail
        let task = Task { @MainActor in
            _ = await previous?.value
            let pending = await self.store.pendingRequests()
            // Cancellation is a barrier: switching away from a manual city
            // must clear its alerts even if the next GPS fix is still missing.
            guard !Task.isCancelled else { return false }
            self.store.remove(identifiers: pending.filter { PrayerNotificationPlan.owns($0.identifier) }.map(\.identifier))
            self.record(pending: [], success: true, failures: 0)
            return true
        }
        tail = task
        return task
    }

    private func isCurrent(_ token: Int) -> Bool { token == generation && !Task.isCancelled }

    private func reconcile(location: CLLocation?, settings: PrayerSettings, calendar: Calendar,
                           now: Date, token: Int) async -> Bool {
        let pending = await store.pendingRequests()
        guard isCurrent(token) else { return false }
        let owned = pending.filter { PrayerNotificationPlan.owns($0.identifier) }
        if !settings.notificationsEnabled || !PrayerNotificationPlan.hasEnabledAlerts(settings) {
            store.remove(identifiers: owned.map(\.identifier))
            record(pending: [], success: true, failures: 0)
            return true
        }
        let authorization = await store.authorizationStatus()
        guard isCurrent(token) else { return false }
        guard authorization == .authorized || authorization == .provisional || authorization == .ephemeral,
              let location else {
            // No permission prompt, GPS request, or destructive queue clear in
            // the background. A temporary lack of inputs must not erase alerts.
            record(pending: owned, success: false, failures: 0)
            return false
        }
        let available = max(0, PrayerNotificationPlan.capacity - (pending.count - owned.count))
        let planned = PrayerNotificationPlan.requests(location: location, settings: settings,
                                                      now: now, calendar: calendar, limit: available)
        guard !planned.isEmpty else {
            record(pending: owned, success: false, failures: 0)
            return false
        }
        let desiredIDs = Set(planned.map(\.identifier))
        let existingByID = Dictionary(uniqueKeysWithValues: pending.map { ($0.identifier, $0) })
        var presentIDs = Set(pending.map(\.identifier))
        var obsolete = owned.filter { !desiredIDs.contains($0.identifier) }
        obsolete.sort {
            ($0.prayerFireDate ?? .distantPast) > ($1.prayerFireDate ?? .distantPast)
        }
        var failures = 0
        for request in planned {
            guard isCurrent(token) else { return false }
            if let existing = existingByID[request.identifier],
               existing.content.isEqual(request.content), existing.trigger?.isEqual(request.trigger) == true {
                continue
            }
            if !presentIDs.contains(request.identifier), presentIDs.count >= PrayerNotificationPlan.capacity {
                // Reclaim only one obsolete slot at a time, furthest date first.
                // Matching IDs are replaced in place without deleting them first.
                guard !obsolete.isEmpty else { failures += 1; continue }
                let removed = obsolete.removeFirst()
                store.remove(identifiers: [removed.identifier])
                presentIDs.remove(removed.identifier)
            }
            do {
                try await store.add(request)
                presentIDs.insert(request.identifier)
            } catch {
                failures += 1
                logger.error("Notification submission failed: \(String(describing: error), privacy: .public)")
            }
        }
        guard isCurrent(token) else { return false }
        // Remove disabled/outdated events only after attempting the new plan.
        store.remove(identifiers: obsolete.map(\.identifier))
        let verified = await store.pendingRequests().filter { PrayerNotificationPlan.owns($0.identifier) }
        guard isCurrent(token) else { return false }
        let verifiedIDs = Set(verified.map(\.identifier))
        let success = failures == 0 && desiredIDs.isSubset(of: verifiedIDs)
        record(pending: verified, success: success, failures: failures)
        return success
    }

    private func record(pending: [UNNotificationRequest], success: Bool, failures: Int) {
        let coverage = pending.compactMap(\.prayerFireDate).max()
        defaults.set(Date(), forKey: "notificationQueueLastChecked")
        defaults.set(pending.count, forKey: "notificationQueueCount")
        defaults.set(coverage, forKey: "notificationQueueScheduledThrough")
        defaults.set(success, forKey: "notificationQueueLastUpdateSucceeded")
        defaults.set(failures, forKey: "notificationQueueSubmissionFailures")
        logger.info("Queue verified: \(pending.count) alerts, success: \(success), submission failures: \(failures)")
    }
}
