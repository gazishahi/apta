import SwiftUI
import CoreLocation

struct OnboardingLocationView: View {
    @ObservedObject var locationService: LocationService
    @Binding var settings: PrayerSettings
    @State private var notificationGranted = false
    @State private var notificationRequested = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Permissions")
                    .font(Typography.onboardingTitle)
                    .foregroundStyle(AptaColors.primary)

                Text("Your location is used to calculate accurate prayer times. It never leaves your device.")
                    .font(Typography.onboardingBody)
                    .foregroundStyle(AptaColors.secondary)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 16) {
                // Location
                if locationService.location != nil {
                    confirmationRow("Location received")
                } else if locationService.authorizationStatus == .denied ||
                          locationService.authorizationStatus == .restricted {
                    Text("Location access denied. Please enable it in Settings.")
                        .font(Typography.onboardingBody)
                        .foregroundStyle(AptaColors.secondary)
                        .padding(.horizontal, 24)
                } else if locationService.authorizationStatus == .notDetermined {
                    permissionButton("Allow Location Access") {
                        locationService.requestPermission()
                    }
                } else {
                    ProgressView()
                        .padding(.horizontal, 24)
                }

                // Notifications
                if notificationGranted {
                    confirmationRow("Notifications enabled")
                } else if !notificationRequested {
                    permissionButton("Enable Prayer Notifications") {
                        notificationRequested = true
                        Task {
                            let granted = await NotificationScheduler.requestPermission()
                            if granted {
                                settings.notificationsEnabled = true
                                notificationGranted = true
                            }
                        }
                    }
                }
            }
        }
    }

    private func permissionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Text(title)
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
