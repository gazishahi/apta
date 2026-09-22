import SwiftUI
import CoreLocation

struct RootCoordinator: View {
    enum AppPhase {
        case splash
        case onboarding
        case main
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var phase: AppPhase = .splash
    @State private var showSettings = false
    @State private var showLocationUpgradePrompt = false
    @ObservedObject private var locationService: LocationService
    @StateObject private var viewModel: PrayerTimesViewModel

    init(locationService: LocationService) {
        self.locationService = locationService
        _viewModel = StateObject(wrappedValue: PrayerTimesViewModel(locationService: locationService))
    }

    private var resolvedColorScheme: ColorScheme? {
        let settings = PrayerSettings.current
        switch settings.theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        case .auto:
            let now = Date()
            if let sunrise = viewModel.sunriseTime, let sunset = viewModel.sunsetTime {
                return (now >= sunrise && now < sunset) ? .light : .dark
            }
            return nil
        }
    }

    var body: some View {
        ZStack {
            switch phase {
            case .splash:
                SplashView(mode: PrayerSettings.hasCompletedOnboarding ? .logoOnly : .onboarding) {
                    withAnimation(AnimationConstants.prayerTransition) {
                        if PrayerSettings.hasCompletedOnboarding {
                            phase = .main
                        } else {
                            phase = .onboarding
                        }
                    }
                }.statusBarHidden()

            case .onboarding:
                OnboardingContainerView(locationService: locationService) {
                    withAnimation(AnimationConstants.prayerTransition) {
                        phase = .main
                    }
                }

            case .main:
                NavigationStack {
                    PrayerTimesView(viewModel: viewModel, locationService: locationService) {
                        showSettings = true
                    }
                    .navigationBarHidden(true)
                    .sheet(isPresented: $showSettings) {
                        NavigationStack {
                            SettingsView {
                                viewModel.recalculate()
                                NotificationScheduler.scheduleUpcoming(location: locationService.location)
                            }
                        }
                    }
                    .onAppear {
                        locationService.refreshAuthorizationState()
                        locationService.requestLocation()
                        viewModel.start()
                        offerLocationUpgradeIfNeeded()
                    }
                    .onDisappear {
                        viewModel.stop()
                    }
                }
            }
        }
        .preferredColorScheme(resolvedColorScheme)
        .alert("Keep Prayer Times Updated While Traveling?", isPresented: $showLocationUpgradePrompt) {
            Button("Not Now", role: .cancel) {
                recordLocationChoice()
            }
            Button("Enable") {
                recordLocationChoice()
                locationService.requestTravelPermission()
            }
        } message: {
            Text("Allow apta to update prayer times, notifications, widgets, and Apple Watch after significant travel, even when you haven't opened the app.")
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                locationService.refreshAuthorizationState()
                if phase != .splash {
                    locationService.requestLocation()
                }
                if phase == .main {
                    offerLocationUpgradeIfNeeded()
                }
            }
        }
        .onChange(of: locationService.location) {
            viewModel.recalculate()
        }
    }

    private func offerLocationUpgradeIfNeeded() {
        guard locationService.manualLocation == nil else { return }
        let defaults = SharedDefaults.suite
        guard LocationUpgradePromptPolicy.shouldOffer(
            hasCompletedOnboarding: PrayerSettings.hasCompletedOnboarding,
            hasMadeChoice: defaults.bool(forKey: SharedDefaults.backgroundLocationChoiceMadeKey),
            authorizationStatus: locationService.authorizationStatus
        ) else { return }
        showLocationUpgradePrompt = true
    }

    private func recordLocationChoice() {
        SharedDefaults.suite.set(true, forKey: SharedDefaults.backgroundLocationChoiceMadeKey)
    }
}

enum LocationUpgradePromptPolicy {
    static func shouldOffer(
        hasCompletedOnboarding: Bool,
        hasMadeChoice: Bool,
        authorizationStatus: CLAuthorizationStatus
    ) -> Bool {
        hasCompletedOnboarding &&
            !hasMadeChoice &&
            authorizationStatus == .authorizedWhenInUse
    }
}
