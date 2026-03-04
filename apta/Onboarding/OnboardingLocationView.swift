import SwiftUI
import CoreLocation

struct OnboardingLocationView: View {
    @ObservedObject var locationService: LocationService

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(Typography.onboardingTitle)
                    .foregroundStyle(AptaColors.primary)

                Text("Your location is used to calculate accurate prayer times. It never leaves your device.")
                    .font(Typography.onboardingBody)
                    .foregroundStyle(AptaColors.secondary)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 16) {
                if locationService.authorizationStatus == .notDetermined {
                    Button {
                        Haptics.light()
                        locationService.requestPermission()
                    } label: {
                        Text("Allow Location Access")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(AptaColors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AptaColors.primary, lineWidth: 1.5)
                            )
                    }
                    .padding(.horizontal, 24)
                } else if locationService.authorizationStatus == .denied ||
                          locationService.authorizationStatus == .restricted {
                    Text("Location access denied. Please enable it in Settings.")
                        .font(Typography.onboardingBody)
                        .foregroundStyle(AptaColors.secondary)
                        .padding(.horizontal, 24)
                } else if locationService.location != nil {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AptaColors.primary)
                        Text("Location received")
                            .font(Typography.onboardingBody)
                            .foregroundStyle(AptaColors.primary)
                    }
                    .padding(.horizontal, 24)
                } else {
                    ProgressView()
                        .padding(.horizontal, 24)
                }
            }
        }
    }
}
