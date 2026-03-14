import SwiftUI
import Foundation

enum BackgroundVariant: String, Codable, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }
}

struct BackgroundTheme: Codable, Equatable {
    var preset: BackgroundPreset?
    var isAdaptive: Bool = true
    var preferredVariant: BackgroundVariant = .light

    static let `default` = BackgroundTheme(preset: nil, isAdaptive: true, preferredVariant: .light)

    func backgroundColor(for colorScheme: ColorScheme) -> Color? {
        guard let preset = preset else { return nil }
        if isAdaptive {
            return colorScheme == .dark ? preset.darkColor : preset.lightColor
        } else {
            return preferredVariant == .dark ? preset.darkColor : preset.lightColor
        }
    }

    func textColor(for colorScheme: ColorScheme) -> Color? {
        guard let preset = preset else { return nil }
        if isAdaptive {
            return colorScheme == .dark ? preset.darkTextColor : preset.lightTextColor
        } else {
            return preferredVariant == .dark ? preset.darkTextColor : preset.lightTextColor
        }
    }

    func effectiveColorScheme(for systemColorScheme: ColorScheme) -> ColorScheme {
        guard preset != nil else { return systemColorScheme }
        if isAdaptive {
            return systemColorScheme
        } else {
            return preferredVariant == .dark ? .dark : .light
        }
    }

    private static let key = "backgroundTheme"
    private static var defaults: UserDefaults { SharedDefaults.suite }

    static var current: BackgroundTheme {
        get {
            guard let data = defaults.data(forKey: key),
                  let theme = try? JSONDecoder().decode(BackgroundTheme.self, from: data) else {
                return BackgroundTheme.default
            }
            return theme
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: key)
            }
        }
    }
}

func == (lhs: BackgroundTheme, rhs: BackgroundTheme) -> Bool {
    lhs.preset == rhs.preset &&
    lhs.isAdaptive == rhs.isAdaptive &&
    lhs.preferredVariant == rhs.preferredVariant
}