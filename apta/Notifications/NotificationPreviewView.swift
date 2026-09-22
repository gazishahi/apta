import SwiftUI

struct NotificationPreviewView: View {
    let settings: PrayerSettings

    private var sampleTime: Date {
        SharedDefaults.prayerCalendar.date(bySettingHour: 13, minute: 15, second: 0, of: Date()) ?? Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NOTIFICATION PREVIEW")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .padding(10)
                    .background(.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("apta").font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text("now").font(.caption).foregroundStyle(.secondary)
                    }
                    Text("Dhuhr").font(.subheadline.weight(.semibold))
                    Text(NotificationMessages.prayerMessage(for: .dhuhr, time: sampleTime,
                                                            date: sampleTime, isRamadan: false,
                                                            settings: settings))
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            Text(settings.notificationStyle == .fun
                 ? "Whimsy adds a playful message that varies by prayer and day."
                 : "Standard shows the prayer name and time.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}
