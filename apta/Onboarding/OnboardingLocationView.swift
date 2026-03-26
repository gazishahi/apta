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
                if locationService.location != nil {
                    confirmationRow("Location received")
                } else if locationService.authorizationStatus == .denied ||
                          locationService.authorizationStatus == .restricted {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location access denied. Please enable it in Settings to get accurate prayer times.")
                            .font(Typography.onboardingBody)
                            .foregroundStyle(AptaColors.secondary)
                            .padding(.horizontal, 24)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                } else {
                    ProgressView()
                        .padding(.horizontal, 24)
                }
            }
        }
        .onAppear {
            if locationService.authorizationStatus == .notDetermined {
                locationService.requestPermission()
            }
        }
    }

    private func confirmationRow(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AptaColors.primary)
            Text(text)
                .font(Typography.onboardingBody)
                .foregroundStyle(AptaColors.primary)
        }
        .frame(maxWidth: .infinity)
    }
}
