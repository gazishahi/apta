import Foundation
import Adhan

struct PrayerSettings: Codable {
    var calculationMethod: AppCalculationMethod = .northAmerica
    var asrMethod: AsrMethod = .standard
    var highLatitudeRule: AppHighLatitudeRule = .middleOfTheNight
    var theme: AppTheme = .system
    var timeFormat: TimeFormat = .twelve
    var hijriAdjustment: Int = 0
    var customFajrAngle: Double?
    var customIshaAngle: Double?
    var notificationsEnabled: Bool = false
    var notificationStyle: NotificationStyle = .simple
    var ramadanNotificationsEnabled: Bool = true
    var fajrNotification: Bool = true
    var dhuhrNotification: Bool = true
    var asrNotification: Bool = true
    var maghribNotification: Bool = true
    var ishaNotification: Bool = true
    var prayerFontSize: PrayerFontSize = .medium

    enum PrayerFontSize: String, CaseIterable, Codable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"

        var id: String { rawValue }

        var upcomingNameSize: CGFloat {
            switch self {
            case .small: return 15
            case .medium: return 17
            case .large: return 20
            }
        }

        var upcomingTimeSize: CGFloat {
            switch self {
            case .small: return 15
            case .medium: return 17
            case .large: return 20
            }
        }
    }

    func isNotificationEnabled(for prayer: PrayerName) -> Bool {
        switch prayer {
        case .fajr: return fajrNotification
        case .dhuhr: return dhuhrNotification
        case .asr: return asrNotification
        case .maghrib: return maghribNotification
        case .isha: return ishaNotification
        case .sunrise: return false
        }
    }

    enum NotificationStyle: String, Codable, CaseIterable, Identifiable {
        case fun = "Whimsy"
        case simple = "Standard"

        var id: String { rawValue }
    }

    enum AsrMethod: String, CaseIterable, Codable, Identifiable {
        case standard = "Standard (Shafi/Maliki/Hanbali)"
        case hanafi = "Hanafi"

        var id: String { rawValue }

        var madhab: Madhab {
            switch self {
            case .standard: return .shafi
            case .hanafi: return .hanafi
            }
        }
    }

    enum AppHighLatitudeRule: String, CaseIterable, Codable, Identifiable {
        case middleOfTheNight = "Middle of the Night"
        case seventhOfTheNight = "Seventh of the Night"
        case twilightAngle = "Twilight Angle"

        var id: String { rawValue }

        var adhanRule: HighLatitudeRule {
            switch self {
            case .middleOfTheNight: return .middleOfTheNight
            case .seventhOfTheNight: return .seventhOfTheNight
            case .twilightAngle: return .twilightAngle
            }
        }
    }

    enum AppTheme: String, CaseIterable, Codable, Identifiable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
        case auto = "Auto"

        var id: String { rawValue }
    }

    enum TimeFormat: String, CaseIterable, Codable, Identifiable {
        case twelve = "12-hour"
        case twentyFour = "24-hour"

        var id: String { rawValue }
    }

    private static let key = "prayerSettings"
    private static var defaults: UserDefaults { SharedDefaults.suite }

    static var current: PrayerSettings {
        get {
            guard let data = defaults.data(forKey: key),
                  let settings = try? JSONDecoder().decode(PrayerSettings.self, from: data) else {
                return PrayerSettings()
            }
            return settings
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: key)
            }
        }
    }

    static var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: "hasCompletedOnboarding") }
        set { defaults.set(newValue, forKey: "hasCompletedOnboarding") }
    }
}
