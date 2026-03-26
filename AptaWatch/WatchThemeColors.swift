import SwiftUI

enum WatchThemeColors {
    static func backgroundColor(isProUser: Bool, preset: BackgroundPreset?) -> Color {
        guard isProUser, let preset = preset else { return .black }
        return preset.darkColor
    }

    static func textColor() -> Color { .white }
    static func secondaryTextColor() -> Color { .white.opacity(0.7) }
    static func tertiaryTextColor() -> Color { .white.opacity(0.5) }
}
