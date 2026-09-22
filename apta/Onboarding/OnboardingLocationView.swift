import SwiftUI
import CoreLocation

struct OnboardingLocationView: View {
    @ObservedObject var locationService: LocationService
    @Binding var choiceMade: Bool
    @State private var showLocationPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Location")
                    .font(Typography.onboardingTitle)
                    .foregroundStyle(AptaColors.primary)

                Text("Choose whether apta should update your prayer times only while you use the app or also after significant travel.")
                    .font(Typography.onboardingBody)
                    .foregroundStyle(AptaColors.secondary)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 16) {
                if let manual = locationService.manualLocation {
                    confirmationRow("Using \(manual.city)")
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
                } else if !choiceMade {
                    permissionOption(
                        title: "Keep Updated While Traveling",
                        description: "Updates prayers, notifications, widgets, and Apple Watch after significant travel.",
                        symbol: "location.fill"
                    ) {
                        selectLocationAccess(travelUpdates: true)
                    }

                    permissionOption(
                        title: "Only While Using apta",
                        description: "Updates your location whenever you open the app.",
                        symbol: "location"
                    ) {
                        selectLocationAccess(travelUpdates: false)
                    }
                } else if locationService.location != nil {
                    confirmationRow(
                        locationService.authorizationStatus == .authorizedAlways
                            ? "Travel updates enabled"
                            : "Location received"
                    )
                } else {
                    ProgressView()
                        .padding(.horizontal, 24)
                }
                Button("Choose a City Manually") { showLocationPicker = true }
                    .font(Typography.onboardingBody)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            LocationPickerView(locationService: locationService)
        }
        .onChange(of: locationService.manualLocation) { _, selection in
            if selection != nil { choiceMade = true }
        }
        .onAppear {
            if locationService.manualLocation != nil { choiceMade = true }
            if locationService.authorizationStatus == .authorizedAlways && !choiceMade {
                choiceMade = true
            }
        }
    }

    private func permissionOption(
        title: String,
        description: String,
        symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 24)
                    .foregroundStyle(AptaColors.primary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Typography.onboardingOption)
                        .foregroundStyle(AptaColors.primary)
                    Text(description)
                        .font(Typography.onboardingBody)
                        .foregroundStyle(AptaColors.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(AptaColors.tertiary.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }

    private func selectLocationAccess(travelUpdates: Bool) {
        Haptics.selection()
        choiceMade = true
        if travelUpdates {
            locationService.requestTravelPermission()
        } else {
            locationService.requestPermission()
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
