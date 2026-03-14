import SwiftUI

enum WidgetBackgroundVariant: String, Codable, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }
}

enum WidgetBackgroundPreset: String, Codable, CaseIterable {
    case emerald
    case indigo
    case rose
    case amber
    case teal
    case slate
    case midnight
    case purple

    var lightColor: Color {
        switch self {
        case .emerald: return Color(hex: "D1FAE5")
        case .indigo: return Color(hex: "E0E7FF")
        case .rose: return Color(hex: "FFE4E6")
        case .amber: return Color(hex: "FEF3C7")
        case .teal: return Color(hex: "CCFBF1")
        case .slate: return Color(hex: "F1F5F9")
        case .midnight: return Color(hex: "DBEAFE")
        case .purple: return Color(hex: "EDE9FE")
        }
    }

    var darkColor: Color {
        switch self {
        case .emerald: return Color(hex: "064E3B")
        case .indigo: return Color(hex: "312E81")
        case .rose: return Color(hex: "881337")
        case .amber: return Color(hex: "78350F")
        case .teal: return Color(hex: "134E4A")
        case .slate: return Color(hex: "1E293B")
        case .midnight: return Color(hex: "1E3A8A")
        case .purple: return Color(hex: "4C1D95")
        }
    }

    var lightTextColor: Color { .black }
    var darkTextColor: Color { .white }
}

struct WidgetBackgroundTheme: Codable {
    var preset: WidgetBackgroundPreset?
    var isAdaptive: Bool
    var preferredVariant: WidgetBackgroundVariant = .light

    static let `default` = WidgetBackgroundTheme(preset: nil, isAdaptive: true, preferredVariant: .light)

    static var current: WidgetBackgroundTheme {
        let defaults = UserDefaults(suiteName: "group.Gazi.apta") ?? .standard
        guard let data = defaults.data(forKey: "backgroundTheme"),
              let theme = try? JSONDecoder().decode(WidgetBackgroundTheme.self, from: data) else {
            return .default
        }
        return theme
    }

    static var isProUser: Bool {
        let defaults = UserDefaults(suiteName: "group.Gazi.apta") ?? .standard
        return defaults.bool(forKey: "isProUser")
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
