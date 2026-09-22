import Foundation
import CoreLocation
import Combine
import WidgetKit

@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: Error?
    @Published var locationName: String = ""
    @Published var heading: CLLocationDirection?
    @Published private(set) var manualLocation = SharedDefaults.manualLocation

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var travelAuthorizationRequest: TravelAuthorizationRequest = .none

    private enum TravelAuthorizationRequest {
        case none
        case whenInUse
        case always
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus

        // Seed from cache so prayers show immediately, even before a fresh GPS fix
        let defaults = SharedDefaults.suite
        let lat = defaults.double(forKey: SharedDefaults.latitudeKey)
        let lon = defaults.double(forKey: SharedDefaults.longitudeKey)
        if lat != 0 || lon != 0 {
            location = CLLocation(latitude: lat, longitude: lon)
        }
        locationName = defaults.string(forKey: SharedDefaults.locationCityKey) ?? ""
        if let manualLocation {
            location = CLLocation(latitude: manualLocation.latitude, longitude: manualLocation.longitude)
            locationName = manualLocation.city
        }

        updateBackgroundMonitoring()
    }

    func requestPermission() {
        guard manualLocation == nil else { return }
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            return
        @unknown default:
            return
        }
    }

    func requestLocation() {
        guard manualLocation == nil else { return }
        manager.requestLocation()
    }

    func selectManualLocation(_ selection: ManualPrayerLocation) {
        geocoder.cancelGeocode()
        travelAuthorizationRequest = .none
        SharedDefaults.manualLocation = selection
        manualLocation = selection
        locationName = selection.city
        error = nil
        stopHeadingUpdates()
        updateBackgroundMonitoring()
        let selected = CLLocation(latitude: selection.latitude, longitude: selection.longitude)
        writeLocationToSharedDefaults(selected)
        SharedDefaults.suite.set(selection.city, forKey: SharedDefaults.locationCityKey)
        SharedDefaults.suite.set(selection.detail, forKey: SharedDefaults.locationRegionKey)
        location = selected
        refreshDependents()
    }

    func useCurrentLocation() {
        guard manualLocation != nil else {
            requestPermission()
            return
        }
        SharedDefaults.manualLocation = nil
        manualLocation = nil
        locationName = ""
        location = nil
        error = nil
        for key in [SharedDefaults.latitudeKey, SharedDefaults.longitudeKey,
                    SharedDefaults.locationTimestampKey, SharedDefaults.locationCityKey,
                    SharedDefaults.locationRegionKey] {
            SharedDefaults.suite.removeObject(forKey: key)
        }
        NotificationScheduler.cancelAll()
        SharedDefaults.suite.set(Date().timeIntervalSince1970, forKey: SharedDefaults.locationUpdatedAtKey)
        refreshDependents()
        updateBackgroundMonitoring()
        requestPermission()
    }

    private func refreshDependents() {
        NotificationScheduler.scheduleUpcoming(location: location)
        WidgetCenter.shared.reloadAllTimelines()
        WatchSyncService.shared.sendSettingsUpdate()
    }

    func refreshAuthorizationState() {
        authorizationStatus = manager.authorizationStatus
        updateBackgroundMonitoring()
    }

    func requestTravelPermission() {
        guard manualLocation == nil else { return }
        switch manager.authorizationStatus {
        case .denied, .restricted:
            return
        case .authorizedAlways:
            updateBackgroundMonitoring()
            manager.requestLocation()
        case .authorizedWhenInUse:
            travelAuthorizationRequest = .always
            manager.requestLocation()
            manager.requestAlwaysAuthorization()
        case .notDetermined:
            travelAuthorizationRequest = .whenInUse
            manager.requestWhenInUseAuthorization()
        @unknown default: return
        }
    }

    func startHeadingUpdates() {
        guard manualLocation == nil, CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
    }

    func stopHeadingUpdates() {
        manager.stopUpdatingHeading()
        heading = nil
    }

    private func writeLocationToSharedDefaults(_ location: CLLocation) {
        let defaults = SharedDefaults.suite
        defaults.set(Date().timeIntervalSince1970, forKey: SharedDefaults.locationUpdatedAtKey)
        defaults.set(location.coordinate.latitude, forKey: SharedDefaults.latitudeKey)
        defaults.set(location.coordinate.longitude, forKey: SharedDefaults.longitudeKey)
        defaults.set(location.timestamp.timeIntervalSince1970, forKey: SharedDefaults.locationTimestampKey)
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.cancelGeocode()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            Task { @MainActor [weak self] in
                guard let self, self.manualLocation == nil, let placemark = placemarks?.first else { return }
                guard self.location?.distance(from: location) ?? .infinity < 5_000 else { return }

                let city = LocationLabelFormatter.city(
                    locality: placemark.locality,
                    subAdministrativeArea: placemark.subAdministrativeArea,
                    administrativeArea: placemark.administrativeArea,
                    country: placemark.country
                )
                self.locationName = city

                let defaults = SharedDefaults.suite
                defaults.set(city, forKey: SharedDefaults.locationCityKey)
                defaults.set(placemark.administrativeArea, forKey: SharedDefaults.locationRegionKey)
            }
        }
    }

    private func updateBackgroundMonitoring() {
        if manualLocation == nil, manager.authorizationStatus == .authorizedAlways,
           CLLocationManager.significantLocationChangeMonitoringAvailable() {
            SharedDefaults.suite.set(true, forKey: SharedDefaults.backgroundLocationChoiceMadeKey)
            manager.startMonitoringSignificantLocationChanges()
        } else {
            manager.stopMonitoringSignificantLocationChanges()
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            guard let self, self.manualLocation == nil, let loc = locations.last else { return }
            let defaults = SharedDefaults.suite
            let lastAcceptedTimestamp = defaults.double(forKey: SharedDefaults.locationTimestampKey)
            guard LocationUpdatePolicy.shouldAccept(
                loc,
                lastAcceptedTimestamp: lastAcceptedTimestamp,
                now: Date()
            ) else { return }

            let movedToDifferentArea = self.location.map { $0.distance(from: loc) >= 20_000 } ?? false
            if movedToDifferentArea {
                self.locationName = ""
                defaults.removeObject(forKey: SharedDefaults.locationCityKey)
                defaults.removeObject(forKey: SharedDefaults.locationRegionKey)
            }

            self.location = loc
            self.writeLocationToSharedDefaults(loc)
            WidgetCenter.shared.reloadAllTimelines()
            NotificationScheduler.scheduleUpcoming(location: loc)
            WatchSyncService.shared.sendSettingsUpdate()
            self.reverseGeocode(loc)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            if newHeading.headingAccuracy >= 0 {
                self.heading = newHeading.trueHeading
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.error = error
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = manager.authorizationStatus
            guard self.manualLocation == nil else {
                self.updateBackgroundMonitoring()
                return
            }
            if manager.authorizationStatus == .authorizedAlways {
                self.travelAuthorizationRequest = .none
                self.updateBackgroundMonitoring()
                manager.requestLocation()
            } else if manager.authorizationStatus == .authorizedWhenInUse {
                self.updateBackgroundMonitoring()
                if self.travelAuthorizationRequest == .whenInUse {
                    self.travelAuthorizationRequest = .always
                    manager.requestLocation()
                    manager.requestAlwaysAuthorization()
                    return
                }

                self.travelAuthorizationRequest = .none
                manager.requestLocation()
            } else if manager.authorizationStatus == .denied ||
                        manager.authorizationStatus == .restricted {
                self.travelAuthorizationRequest = .none
                self.updateBackgroundMonitoring()
            } else if manager.authorizationStatus == .notDetermined {
                self.travelAuthorizationRequest = .none
                self.updateBackgroundMonitoring()
            }
        }
    }
}

enum LocationLabelFormatter {
    static func city(
        locality: String?,
        subAdministrativeArea: String?,
        administrativeArea: String?,
        country: String?
    ) -> String {
        [locality, subAdministrativeArea, administrativeArea, country]
            .compactMap { value in
                let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return trimmed.isEmpty ? nil : trimmed
            }
            .first ?? "Current Location"
    }
}

enum LocationUpdatePolicy {
    static func shouldAccept(
        _ candidate: CLLocation,
        lastAcceptedTimestamp: TimeInterval,
        now: Date
    ) -> Bool {
        guard candidate.horizontalAccuracy >= 0,
              candidate.horizontalAccuracy <= 20_000 else {
            return false
        }

        let age = now.timeIntervalSince(candidate.timestamp)
        guard age >= -300, age <= 2 * 60 * 60 else { return false }
        return lastAcceptedTimestamp == 0 || candidate.timestamp.timeIntervalSince1970 > lastAcceptedTimestamp
    }
}
