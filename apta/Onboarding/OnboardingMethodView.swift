import SwiftUI

struct OnboardingMethodView: View {
    @Binding var selection: AppCalculationMethod
    let suggested: AppCalculationMethod
    @State private var showAllMethods = false

    private var methods: [AppCalculationMethod] {
        AppCalculationMethod.allCases.filter { $0 != .other }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Calculation Method")
                    .font(Typography.onboardingTitle)
                    .foregroundStyle(AptaColors.primary)

                Text("Based on your region, we suggest \(suggested.rawValue). You can change this anytime in settings.")
                    .font(Typography.onboardingBody)
                    .foregroundStyle(AptaColors.secondary)
            }
            .padding(.horizontal, 24)

            // Suggested method as a prominent confirmed selection
            Button {
                Haptics.selection()
                selection = suggested
            } label: {
                HStack {
                    Text(suggested.rawValue)
                        .font(Typography.onboardingOption)
                        .foregroundStyle(AptaColors.primary)
                    Spacer()
                    if selection == suggested {
                        Image(systemName: "checkmark")
                            .foregroundStyle(AptaColors.primary)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
            }

            Button {
                withAnimation(AnimationConstants.prayerTransition) {
                    showAllMethods.toggle()
                }
            } label: {
                Text(showAllMethods ? "Show less" : "Show all methods")
                    .font(Typography.onboardingBody)
                    .foregroundStyle(AptaColors.secondary)
            }
            .padding(.horizontal, 24)

            if showAllMethods {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(methods.filter { $0 != suggested }) { method in
                            Button {
                                Haptics.selection()
                                selection = method
                            } label: {
                                HStack {
                                    Text(method.rawValue)
                                        .font(Typography.onboardingOption)
                                        .foregroundStyle(AptaColors.primary)
                                    Spacer()
                                    if selection == method {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(AptaColors.primary)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                            }

                            Divider().padding(.leading, 24)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
