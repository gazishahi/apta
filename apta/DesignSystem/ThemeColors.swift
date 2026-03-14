import SwiftUI

enum ThemeColors {
    static func backgroundColor(for colorScheme: ColorScheme) -> Color {
        let theme = BackgroundTheme.current
        if let customColor = theme.backgroundColor(for: colorScheme) {
            return customColor
        }
        return AptaColors.background
    }

    static func textColor(for colorScheme: ColorScheme) -> Color {
        let theme = BackgroundTheme.current
        let effectiveScheme = theme.effectiveColorScheme(for: colorScheme)
        if let customColor = theme.textColor(for: effectiveScheme) {
            return customColor
        }
        return AptaColors.primary
    }

    static func secondaryTextColor(for colorScheme: ColorScheme) -> Color {
        let theme = BackgroundTheme.current
        let effectiveScheme = theme.effectiveColorScheme(for: colorScheme)
        if theme.preset != nil {
            return textColor(for: effectiveScheme).opacity(0.7)
        }
        return AptaColors.secondary
    }

    static func tertiaryTextColor(for colorScheme: ColorScheme) -> Color {
        let theme = BackgroundTheme.current
        let effectiveScheme = theme.effectiveColorScheme(for: colorScheme)
        if theme.preset != nil {
            return textColor(for: effectiveScheme).opacity(0.5)
        }
        return AptaColors.tertiary
    }

    static func quaternaryTextColor(for colorScheme: ColorScheme) -> Color {
        let theme = BackgroundTheme.current
        let effectiveScheme = theme.effectiveColorScheme(for: colorScheme)
        if theme.preset != nil {
            return textColor(for: effectiveScheme).opacity(0.25)
        }
        return AptaColors.secondary.opacity(0.25)
    }
}
