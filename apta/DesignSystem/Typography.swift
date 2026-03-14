import SwiftUI

enum Typography {
    static let currentPrayerName = Font.system(size: 13, weight: .medium, design: .default)
    static let currentPrayerNameKerning: CGFloat = 4.0

    static let currentTime = Font.system(size: 88, weight: .regular, design: .default)
    static let currentTimeKerning: CGFloat = -2.0

    static let countdown = Font.system(size: 14, weight: .light, design: .default)

    static var upcomingPrayerName: Font {
        let size = PrayerSettings.current.prayerFontSize.upcomingNameSize
        return Font.system(size: size, weight: .regular, design: .default)
    }
    static var upcomingPrayerTime: Font {
        let size = PrayerSettings.current.prayerFontSize.upcomingTimeSize
        return Font.system(size: size, weight: .regular, design: .default)
    }

    static let splashLetter = Font.system(size: 48, weight: .bold, design: .default)
    static let splashLogoText = Font.system(size: 48, weight: .bold, design: .default)
    static let splashWord = Font.system(size: 14, weight: .light, design: .default)
    static let splashWordKerning: CGFloat = 3.0

    static let settingsHeader = Font.system(size: 13, weight: .medium, design: .default)
    static let settingsHeaderKerning: CGFloat = 3.0

    static let onboardingTitle = Font.system(size: 28, weight: .bold, design: .default)
    static let onboardingBody = Font.system(size: 15, weight: .regular, design: .default)
    static let onboardingOption = Font.system(size: 17, weight: .regular, design: .default)
}
