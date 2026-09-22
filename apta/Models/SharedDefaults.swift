import Foundation

enum SharedDefaults {
    static let suiteName = "group.Gazi.apta"

    static var suite: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // Keys for shared location data
    static let latitudeKey = "shared_latitude"
    static let longitudeKey = "shared_longitude"
    static let locationTimestampKey = "shared_location_timestamp"
    static let locationCityKey = "shared_location_city"
    static let locationRegionKey = "shared_location_region"
    static let manualLocationKey = "manual_location_v1"
    static let locationUpdatedAtKey = "location_settings_updated_at"

    /// Messages and application contexts can arrive out of order on Watch.
    static func storeLocationPayload(_ payload: [String: Any], in defaults: UserDefaults = suite) {
        let incoming = payload[locationUpdatedAtKey] as? Double ?? 0
        guard incoming >= defaults.double(forKey: locationUpdatedAtKey) else { return }
        for key in [latitudeKey, longitudeKey, manualLocationKey, locationUpdatedAtKey] {
            if let value = payload[key] { defaults.set(value, forKey: key) }
        }
    }
    static var manualLocation: ManualPrayerLocation? {
        get {
            guard let data = suite.data(forKey: manualLocationKey) else { return nil }
            return try? JSONDecoder().decode(ManualPrayerLocation.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                suite.set(data, forKey: manualLocationKey)
            } else {
                suite.removeObject(forKey: manualLocationKey)
            }
        }
    }

    static var prayerTimeZone: TimeZone {
        timeZone(for: manualLocation)
    }

    static func timeZone(for selection: ManualPrayerLocation?) -> TimeZone {
        selection.flatMap { TimeZone(identifier: $0.timeZoneIdentifier) } ?? .current
    }

    static var prayerCalendar: Calendar { calendar(identifier: .gregorian) }

    static func calendar(identifier: Calendar.Identifier) -> Calendar {
        var calendar = Calendar(identifier: identifier)
        calendar.timeZone = prayerTimeZone
        return calendar
    }
    static let backgroundLocationChoiceMadeKey = "background_location_choice_made_v1"

    // Keys for background theme
    static let backgroundThemeKey = "backgroundTheme"
    static let isProUserKey = "isProUser"
    static let proStatusUpdatedAtKey = "proStatusUpdatedAt"

    /// Pro status. A simulator defaults to Pro when no explicit test value has
    /// been stored, while still allowing locked-state testing by storing false.
    static var isProUser: Bool {
        #if targetEnvironment(simulator)
        if suite.object(forKey: isProUserKey) == nil {
            return true
        }
        return suite.bool(forKey: isProUserKey)
        #else
        return suite.bool(forKey: isProUserKey)
        #endif
    }
}

nonisolated struct ManualPrayerLocation: Codable, Hashable, Sendable {
    let city: String
    let detail: String
    let latitude: Double
    let longitude: Double
    let timeZoneIdentifier: String
}

enum ProStatusResolver {
    static func resolve(
        storedValue: Bool,
        storedUpdatedAt: TimeInterval,
        contextValue: Bool?,
        contextUpdatedAt: TimeInterval?
    ) -> Bool {
        guard let contextValue else { return storedValue }
        let contextTimestamp = contextUpdatedAt ?? 0
        return contextTimestamp >= storedUpdatedAt ? contextValue : storedValue
    }
}
