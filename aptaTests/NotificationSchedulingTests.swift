import CoreLocation
import Foundation
import Testing
import UserNotifications
@testable import apta

@MainActor
struct NotificationSchedulingTests {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: "America/New_York")!
        return value
    }
    private var now: Date { calendar.date(from: DateComponents(year: 2030, month: 3, day: 9, hour: 12))! }
    private var location: CLLocation { CLLocation(latitude: 40.7128, longitude: -74.0060) }
    private var enabled: PrayerSettings {
        var settings = PrayerSettings()
        settings.notificationsEnabled = true
        return settings
    }
    private func plan(_ settings: PrayerSettings, at date: Date? = nil, limit: Int = 60) -> [UNNotificationRequest] {
        PrayerNotificationPlan.requests(location: location, settings: settings, now: date ?? now,
                                        calendar: calendar, limit: limit)
    }
    private func isolatedDefaults() -> (String, UserDefaults) {
        let name = "apta-notification-tests-\(UUID().uuidString)"
        return (name, UserDefaults(suiteName: name)!)
    }

    @Test func defaultQueueExtendsWellBeyondThreeDaysAcrossDST() throws {
        let requests = plan(enabled)
        #expect(requests.count == 60)
        #expect(Set(requests.map(\.identifier)).count == 60)
        let dates = requests.compactMap { $0.prayerFireDate }
        #expect(dates.count == 60)
        #expect(dates == dates.sorted())
        #expect(dates.allSatisfy { $0 > now })
        #expect(try #require(dates.last) > calendar.date(byAdding: .day, value: 10, to: now)!)
        #expect(requests.allSatisfy { !($0.trigger?.repeats ?? true) })
    }

    @Test func allOptionalAlertsRemainBoundedSortedAndPaired() {
        var settings = enabled
        settings.preNotificationMinutes = 30
        settings.sunriseNotification = true
        settings.showIshraq = true
        settings.ishraqNotification = true
        settings.showHanbaliBoundaries = true
        settings.boundaryNotificationsEnabled = true
        let requests = plan(settings)
        let dates = requests.compactMap { $0.prayerFireDate }
        let ids = Set(requests.map(\.identifier))
        #expect(requests.count <= 60)
        #expect(dates == dates.sorted())
        #expect(ids.contains { $0.contains("-boundary-") })
        #expect(ids.contains { $0.hasPrefix("Sunrise-") })
        #expect(ids.contains { $0.hasPrefix("Ishraq-") })
        for id in ids where id.contains("-pre-") {
            #expect(ids.contains(id.replacingOccurrences(of: "-pre-", with: "-")))
        }
        for limit in 1...14 { #expect(plan(settings, limit: limit).count <= limit) }
    }

    @Test func savedLocationNeedsNoLiveLocationPermission() throws {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        #expect(NotificationScheduler.savedLocation(in: defaults) == nil)
        defaults.set(0.0, forKey: SharedDefaults.latitudeKey)
        defaults.set(0.0, forKey: SharedDefaults.longitudeKey)
        #expect(NotificationScheduler.savedLocation(in: defaults) != nil)
        let manual = ManualPrayerLocation(city: "London", detail: "United Kingdom", latitude: 51.5,
                                          longitude: -0.12, timeZoneIdentifier: "Europe/London")
        defaults.set(try JSONEncoder().encode(manual), forKey: SharedDefaults.manualLocationKey)
        #expect(NotificationScheduler.savedLocation(in: defaults)?.coordinate.latitude == 51.5)
    }

    @Test func refillAfterSeveralDaysExtendsQueueWithoutDuplicates() async {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = FakeNotificationStore()
        let queue = NotificationQueueCoordinator(store: store, defaults: defaults)
        #expect(await queue.enqueue(location: location, settings: enabled, calendar: calendar, now: now).value)
        let originalEnd = store.requests.values.compactMap { $0.prayerFireDate }.max()!
        let later = calendar.date(byAdding: .day, value: 4, to: now)!
        store.requests = store.requests.filter { ($0.value.prayerFireDate ?? .distantPast) > later }
        #expect(await queue.enqueue(location: location, settings: enabled, calendar: calendar, now: later).value)
        #expect(store.requests.count == 60)
        #expect(store.maximumCount <= 60)
        #expect(store.requests.values.compactMap { $0.prayerFireDate }.max()! > originalEnd)
    }

    @Test func failedReplacementKeepsPreviouslyScheduledAlertsAndReportsFailure() async {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let existing = plan(enabled)
        let store = FakeNotificationStore(existing)
        store.rejectAdds = true
        let queue = NotificationQueueCoordinator(store: store, defaults: defaults)
        var updated = enabled
        updated.notificationStyle = .fun
        #expect(!(await queue.enqueue(location: location, settings: updated, calendar: calendar, now: now).value))
        #expect(Set(store.requests.keys) == Set(existing.map(\.identifier)))
        #expect(store.removedIDs.isEmpty)
        #expect(defaults.integer(forKey: "notificationQueueSubmissionFailures") == 60)
        #expect(!defaults.bool(forKey: "notificationQueueLastUpdateSucceeded"))
    }

    @Test func unchangedQueueDoesNotResubmitAlerts() async {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = FakeNotificationStore(plan(enabled))
        let queue = NotificationQueueCoordinator(store: store, defaults: defaults)
        #expect(await queue.enqueue(location: location, settings: enabled, calendar: calendar, now: now).value)
        #expect(store.addCount == 0)
        #expect(store.removedIDs.isEmpty)
    }

    @Test func expiredTaskStopsSubmittingAndNextRefreshCanRecover() async {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = FakeNotificationStore()
        let queue = NotificationQueueCoordinator(store: store, defaults: defaults)
        let update = queue.enqueue(location: location, settings: enabled, calendar: calendar, now: now)
        store.onFirstAdd = { update.cancel() }
        #expect(!(await update.value))
        #expect(store.addCount == 1)
        #expect(await queue.enqueue(location: location, settings: enabled, calendar: calendar, now: now).value)
        #expect(store.requests.count == 60)
    }

    @Test func missingLocationOrDeniedNotificationsDoesNotEraseExistingQueue() async {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = FakeNotificationStore(plan(enabled))
        let queue = NotificationQueueCoordinator(store: store, defaults: defaults)
        #expect(!(await queue.enqueue(location: nil, settings: enabled, calendar: calendar, now: now).value))
        store.status = .denied
        #expect(!(await queue.enqueue(location: location, settings: enabled, calendar: calendar, now: now).value))
        #expect(store.requests.count == 60)
        #expect(store.removedIDs.isEmpty)
    }

    @Test func cancellationBarrierSurvivesMissingNextLocation() async {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = FakeNotificationStore(plan(enabled))
        let queue = NotificationQueueCoordinator(store: store, defaults: defaults)
        let cancellation = queue.cancelPending()
        let update = queue.enqueue(location: nil, settings: enabled, calendar: calendar, now: now)
        #expect(await cancellation.value)
        #expect(!(await update.value))
        #expect(store.requests.isEmpty)
    }

    @Test func disablingDuringSubmissionWinsOverInFlightUpdate() async {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = FakeNotificationStore()
        let queue = NotificationQueueCoordinator(store: store, defaults: defaults)
        var cancellation: Task<Bool, Never>?
        store.onFirstAdd = { cancellation = queue.cancelPending() }
        #expect(!(await queue.enqueue(location: location, settings: enabled, calendar: calendar, now: now).value))
        _ = await cancellation?.value
        #expect(store.requests.isEmpty)
    }

    @Test func latestSettingsWinWhenUpdatesOverlap() async {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = FakeNotificationStore()
        let queue = NotificationQueueCoordinator(store: store, defaults: defaults)
        var updated = enabled
        updated.fajrNotification = false
        var newer: Task<Bool, Never>?
        store.onFirstAdd = {
            newer = queue.enqueue(location: location, settings: updated, calendar: calendar, now: now)
        }
        #expect(!(await queue.enqueue(location: location, settings: enabled, calendar: calendar, now: now).value))
        #expect(await newer?.value == true)
        #expect(!store.requests.keys.contains { $0.hasPrefix("Fajr-") })
        #expect(store.requests.count == 60)
    }

    @Test func unrelatedNotificationsArePreservedAndCountTowardCapacity() async {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let unrelated = UNNotificationRequest(identifier: "unrelated", content: UNMutableNotificationContent(),
                                              trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false))
        let store = FakeNotificationStore([unrelated])
        let queue = NotificationQueueCoordinator(store: store, defaults: defaults)
        #expect(await queue.enqueue(location: location, settings: enabled, calendar: calendar, now: now).value)
        #expect(store.requests.count == 60)
        #expect(store.maximumCount <= 60)
        var off = enabled
        off.notificationsEnabled = false
        #expect(await queue.enqueue(location: location, settings: off, calendar: calendar, now: now).value)
        #expect(Set(store.requests.keys) == ["unrelated"])
    }

    @Test func verificationDetectsSilentlyMissingRequests() async {
        let (name, defaults) = isolatedDefaults()
        defer { defaults.removePersistentDomain(forName: name) }
        let store = FakeNotificationStore()
        store.dropAdds = true
        let queue = NotificationQueueCoordinator(store: store, defaults: defaults)
        #expect(!(await queue.enqueue(location: location, settings: enabled, calendar: calendar, now: now).value))
        #expect(!defaults.bool(forKey: "notificationQueueLastUpdateSucceeded"))
    }

    @Test func notificationBackgroundModeAndIdentifierArePackaged() {
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        let identifiers = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String] ?? []
        #expect(modes.contains("fetch"))
        #expect(identifiers.contains(NotificationBackgroundRefresh.identifier))
    }
}

@MainActor
private final class FakeNotificationStore: NotificationStore {
    enum Failure: Error { case submission }
    var requests: [String: UNNotificationRequest]
    var status: UNAuthorizationStatus = .authorized
    var rejectAdds = false
    var dropAdds = false
    var removedIDs: [String] = []
    var maximumCount = 0
    var addCount = 0
    var onFirstAdd: (() -> Void)?

    init(_ requests: [UNNotificationRequest] = []) {
        self.requests = Dictionary(uniqueKeysWithValues: requests.map { ($0.identifier, $0) })
        maximumCount = requests.count
    }
    func authorizationStatus() async -> UNAuthorizationStatus { status }
    func pendingRequests() async -> [UNNotificationRequest] { Array(requests.values) }
    func add(_ request: UNNotificationRequest) async throws {
        addCount += 1
        let callback = onFirstAdd
        onFirstAdd = nil
        callback?()
        if rejectAdds { throw Failure.submission }
        if !dropAdds { requests[request.identifier] = request }
        maximumCount = max(maximumCount, requests.count)
    }
    func remove(identifiers: [String]) {
        removedIDs.append(contentsOf: identifiers)
        for id in identifiers { requests.removeValue(forKey: id) }
    }
}
