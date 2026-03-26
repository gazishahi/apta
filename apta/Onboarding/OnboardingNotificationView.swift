import SwiftUI

struct OnboardingNotificationView: View {
    @Binding var settings: PrayerSettings
    @State private var notificationGranted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notifications")
                    .font(Typography.onboardingTitle)
                    .foregroundStyle(AptaColors.primary)

                Text("Get reminded for each prayer time. You can change this anytime in Settings.")
                    .font(Typography.onboardingBody)
                    .foregroundStyle(AptaColors.secondary)
            }
            .padding(.horizontal, 24)

            if notificationGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AptaColors.primary)
                    Text("Notifications enabled")
                        .font(Typography.onboardingBody)
                        .foregroundStyle(AptaColors.primary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
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
