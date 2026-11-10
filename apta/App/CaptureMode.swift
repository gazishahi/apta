#if DEBUG
import Foundation

/// Debug-only hooks for App Store screenshot captures.
/// - `-CaptureScreen <settings|location|qibla>` opens that screen directly.
/// - `-CaptureTime HH:mm` pins the clock used for the current prayer and countdown.
/// - `-CaptureQuery <city>` prefills the location search.
enum CaptureMode {
    enum Screen: String {
        case settings
        case location
        case qibla
    }

    private static var defaults: UserDefaults { .standard }

    static var isActive: Bool {
        ["CaptureScreen", "CaptureTime", "CaptureQuery"].contains { defaults.object(forKey: $0) != nil }
    }

    static var screen: Screen? {
        defaults.string(forKey: "CaptureScreen").flatMap(Screen.init(rawValue:))
    }

    static var query: String? {
        defaults.string(forKey: "CaptureQuery")
    }

    /// Today at the `-CaptureTime` clock time.
    static var now: Date? {
        guard let value = defaults.string(forKey: "CaptureTime") else { return nil }
        let parts = value.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        let calendar = SharedDefaults.prayerCalendar
        return calendar.date(bySettingHour: parts[0], minute: parts[1], second: 0, of: Date())
    }
}
#endif
