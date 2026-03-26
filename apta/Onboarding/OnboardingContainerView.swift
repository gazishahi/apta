import SwiftUI
import CoreLocation

struct OnboardingContainerView: View {
    let onComplete: () -> Void

    @State private var step = 0
    @State private var settings: PrayerSettings
    @StateObject private var locationService = LocationService()

    private let totalSteps = 4
    private let suggested: AppCalculationMethod

    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        let method = AppCalculationMethod.suggestedForLocale()
        self.suggested = method
        var initial = PrayerSettings()
        initial.calculationMethod = method
        _settings = State(initialValue: initial)
    }

    private var isLastStep: Bool { step == totalSteps - 1 }

    private var buttonDisabled: Bool {
        if step == 2 {
            let status = locationService.authorizationStatus
            return locationService.location == nil
                && status != .denied
                && status != .restricted
        }
        return false
    }

    var body: some View {
        ZStack {
            AptaColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Group {
                    switch step {
                    case 0:
                        OnboardingMethodView(selection: $settings.calculationMethod, suggested: suggested)
                    case 1:
                        OnboardingPreferencesView(asrMethod: $settings.asrMethod, highLatitudeRule: $settings.highLatitudeRule)
                    case 2:
                        OnboardingLocationView(locationService: locationService)
                    case 3:
                        OnboardingNotificationView(settings: $settings)
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                    Button {
                        Haptics.light()
                        advance()
                    } label: {
                        Text(isLastStep ? "Get Started" : "Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AptaColors.background)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AptaColors.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .disabled(buttonDisabled)
            }
        }
    }

    private func advance() {
        withAnimation(AnimationConstants.prayerTransition) {
            if step < totalSteps - 1 {
                step += 1
            } else {
                finish()
            }
        }
    }

    private func finish() {
        PrayerSettings.current = settings
        PrayerSettings.hasCompletedOnboarding = true
        Task.detached { WatchSyncService.shared.sendSettingsUpdate() }
        onComplete()
    }
}
