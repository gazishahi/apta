import SwiftUI

struct RootCoordinator: View {
    enum AppPhase {
        case splash
        case onboarding
        case main
    }

    @Environment(\.scenePhase) private var scenePhase
    @State private var phase: AppPhase = .splash
    @State private var showSettings = false
    @StateObject private var locationService = LocationService()
    @StateObject private var viewModel: PrayerTimesViewModel

    init() {
        let locService = LocationService()
        _locationService = StateObject(wrappedValue: locService)
        _viewModel = StateObject(wrappedValue: PrayerTimesViewModel(locationService: locService))
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
                OnboardingContainerView {
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
                            }
                        }
                    }
                    .onAppear {
                        locationService.requestLocation()
                        viewModel.start()
                    }
                    .onDisappear {
                        viewModel.stop()
                    }
                }
            }
        }
        .preferredColorScheme(resolvedColorScheme)
        .onChange(of: scenePhase) {
            if scenePhase == .active, phase == .main {
                locationService.requestLocation()
            }
        }
        .onChange(of: locationService.location) {
            viewModel.recalculate()
            if let loc = locationService.location {
                NotificationScheduler.scheduleUpcoming(location: loc)
                WatchSyncService.shared.sendSettingsUpdate()
            }
        }
    }
}
