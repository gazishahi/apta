import Foundation
import Adhan

struct PrayerSettings: Codable, Equatable {
    var calculationMethod: AppCalculationMethod = .northAmerica
    var asrMethod: AsrMethod = .standard
    var highLatitudeRule: AppHighLatitudeRule = .middleOfTheNight
    var theme: AppTheme = .system
    var timeFormat: TimeFormat = .twelve
    var hijriAdjustment: Int = 0
    var customFajrAngle: Double?
    var customIshaAngle: Double?
    var notificationsEnabled: Bool = false
    var showIshraq: Bool = false
    var ishraqNotification: Bool = false
    var simpleMode: Bool = false
    var notificationStyle: NotificationStyle = .simple
    var ramadanNotificationsEnabled: Bool = true
    var sunriseNotification: Bool = false
    var fajrNotification: Bool = true
    var dhuhrNotification: Bool = true
    var asrNotification: Bool = true
    var maghribNotification: Bool = true
    var ishaNotification: Bool = true
    var prayerFontSize: PrayerFontSize = .medium
    var countdownStyle: CountdownStyle = .compact
    var prominentCountdown: Bool = false
    var showHanbaliBoundaries: Bool = false
    var boundaryNotificationsEnabled: Bool = true

    init() {}

    private enum CodingKeys: String, CodingKey {
        case calculationMethod
        case asrMethod
        case highLatitudeRule
        case theme
        case timeFormat
        case hijriAdjustment
        case customFajrAngle
        case customIshaAngle
        case notificationsEnabled
        case showIshraq
        case ishraqNotification
        case simpleMode
        case notificationStyle
        case ramadanNotificationsEnabled
        case sunriseNotification
        case fajrNotification
        case dhuhrNotification
        case asrNotification
        case maghribNotification
        case ishaNotification
        case prayerFontSize
        case countdownStyle
        case prominentCountdown
        case showHanbaliBoundaries
        case boundaryNotificationsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calculationMethod = try container.decodeIfPresent(AppCalculationMethod.self, forKey: .calculationMethod) ?? .northAmerica
        asrMethod = try container.decodeIfPresent(AsrMethod.self, forKey: .asrMethod) ?? .standard
        highLatitudeRule = try container.decodeIfPresent(AppHighLatitudeRule.self, forKey: .highLatitudeRule) ?? .middleOfTheNight
        theme = try container.decodeIfPresent(AppTheme.self, forKey: .theme) ?? .system
        timeFormat = try container.decodeIfPresent(TimeFormat.self, forKey: .timeFormat) ?? .twelve
        hijriAdjustment = try container.decodeIfPresent(Int.self, forKey: .hijriAdjustment) ?? 0
        customFajrAngle = try container.decodeIfPresent(Double.self, forKey: .customFajrAngle)
        customIshaAngle = try container.decodeIfPresent(Double.self, forKey: .customIshaAngle)
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? false
        showIshraq = try container.decodeIfPresent(Bool.self, forKey: .showIshraq) ?? false
        ishraqNotification = try container.decodeIfPresent(Bool.self, forKey: .ishraqNotification) ?? false
        simpleMode = try container.decodeIfPresent(Bool.self, forKey: .simpleMode) ?? false
        notificationStyle = try container.decodeIfPresent(NotificationStyle.self, forKey: .notificationStyle) ?? .simple
        ramadanNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .ramadanNotificationsEnabled) ?? true
        sunriseNotification = try container.decodeIfPresent(Bool.self, forKey: .sunriseNotification) ?? false
        fajrNotification = try container.decodeIfPresent(Bool.self, forKey: .fajrNotification) ?? true
        dhuhrNotification = try container.decodeIfPresent(Bool.self, forKey: .dhuhrNotification) ?? true
        asrNotification = try container.decodeIfPresent(Bool.self, forKey: .asrNotification) ?? true
        maghribNotification = try container.decodeIfPresent(Bool.self, forKey: .maghribNotification) ?? true
        ishaNotification = try container.decodeIfPresent(Bool.self, forKey: .ishaNotification) ?? true
        prayerFontSize = try container.decodeIfPresent(PrayerFontSize.self, forKey: .prayerFontSize) ?? .medium
        countdownStyle = try container.decodeIfPresent(CountdownStyle.self, forKey: .countdownStyle) ?? .compact
        prominentCountdown = try container.decodeIfPresent(Bool.self, forKey: .prominentCountdown) ?? false
        showHanbaliBoundaries = try container.decodeIfPresent(Bool.self, forKey: .showHanbaliBoundaries) ?? false
        boundaryNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .boundaryNotificationsEnabled) ?? true
    }

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

        var countdownSize: CGFloat {
            switch self {
            case .small: return 13
            case .medium: return 14
            case .large: return 20
            }
        }
    }

    enum CountdownStyle: String, CaseIterable, Codable, Identifiable {
        case compact = "Compact"
        case live = "Live"

        var id: String { rawValue }
    }

    func isNotificationEnabled(for prayer: PrayerName) -> Bool {
        switch prayer {
        case .fajr: return fajrNotification
        case .dhuhr: return dhuhrNotification
        case .asr: return asrNotification
        case .maghrib: return maghribNotification
        case .isha: return ishaNotification
        case .sunrise: return sunriseNotification
        case .ishraq: return ishraqNotification
        }
    }

    enum NotificationStyle: String, Codable, CaseIterable, Identifiable {
        case fun = "Whimsy"
        case simple = "Standard"

        var id: String { rawValue }
    }

    enum AsrMethod: String, CaseIterable, Codable, Identifiable {
        case standard = "Standard"
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

    enum CalendarType: String, CaseIterable, Codable, Identifiable {
        case islamic = "Hijri"
        case gregorian = "Gregorian"

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
