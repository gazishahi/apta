import SwiftUI

struct OnboardingPreferencesView: View {
    @Binding var asrMethod: PrayerSettings.AsrMethod
    @Binding var highLatitudeRule: PrayerSettings.AppHighLatitudeRule

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Preferences")
                    .font(Typography.onboardingTitle)
                    .foregroundStyle(AptaColors.primary)

                Text("Fine-tune how prayer times are calculated.")
                    .font(Typography.onboardingBody)
                    .foregroundStyle(AptaColors.secondary)
            }
            .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 24) {
                // Asr section
                VStack(alignment: .leading, spacing: 12) {
                    Text("ASR CALCULATION")
                        .font(Typography.settingsHeader)
                        .kerning(Typography.settingsHeaderKerning)
                        .foregroundStyle(AptaColors.tertiary)
                        .padding(.horizontal, 24)

                    VStack(spacing: 0) {
                        ForEach(PrayerSettings.AsrMethod.allCases) { method in
                            Button {
                                Haptics.selection()
                                asrMethod = method
                            } label: {
                                HStack {
                                    Text(method.rawValue)
                                        .font(Typography.onboardingOption)
                                        .foregroundStyle(AptaColors.primary)
                                    Spacer()
                                    if asrMethod == method {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AptaColors.primary)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                            }

                            if method != PrayerSettings.AsrMethod.allCases.last {
                                Divider().padding(.leading, 24)
                            }
                        }
                    }
                }

                // High latitude section
                VStack(alignment: .leading, spacing: 12) {
                    Text("HIGH LATITUDE")
                        .font(Typography.settingsHeader)
                        .kerning(Typography.settingsHeaderKerning)
                        .foregroundStyle(AptaColors.tertiary)
                        .padding(.horizontal, 24)

                    VStack(spacing: 0) {
                        ForEach(PrayerSettings.AppHighLatitudeRule.allCases) { rule in
                            Button {
                                Haptics.selection()
                                highLatitudeRule = rule
                            } label: {
                                HStack {
                                    Text(rule.rawValue)
                                        .font(Typography.onboardingOption)
                                        .foregroundStyle(AptaColors.primary)
                                    Spacer()
                                    if highLatitudeRule == rule {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AptaColors.primary)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                            }

                            if rule != PrayerSettings.AppHighLatitudeRule.allCases.last {
                                Divider().padding(.leading, 24)
                            }
                        }
                    }
                }
            }
        }
    }
}
