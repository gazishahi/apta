import SwiftUI

enum AnimationConstants {
    static let splashLetterStagger: Double = 0.12
    static let splashWordDelay: Double = 0.9
    static let splashWordStagger: Double = 0.15
    static let splashFadeOutDelay: Double = 2.2
    static let splashTotalDuration: Double = 2.6

    static let splashLogoFadeOutDelay: Double = 0.8
    static let splashLogoTotalDuration: Double = 1.2
    static let splashLogoMergeDuration: Double = 0.5
    static let splashLogoStartOffset: CGFloat = 80
    static let splashLogoPtaMergeOffset: CGFloat = -40

    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let prayerTransition = Animation.easeInOut(duration: 0.4)
    static let sheetPresentation = Animation.spring(response: 0.4, dampingFraction: 0.9)
}
