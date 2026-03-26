import Foundation
import CoreLocation
import Combine

@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: Error?
    @Published var locationName: String = ""
    @Published var heading: CLLocationDirection?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer

        // Seed from cache so prayers show immediately, even before a fresh GPS fix
        let defaults = SharedDefaults.suite
        let lat = defaults.double(forKey: SharedDefaults.latitudeKey)
        let lon = defaults.double(forKey: SharedDefaults.longitudeKey)
        if lat != 0 || lon != 0 {
            location = CLLocation(latitude: lat, longitude: lon)
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func startHeadingUpdates() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
    }

    func stopHeadingUpdates() {
        manager.stopUpdatingHeading()
        heading = nil
    }

    private func writeLocationToSharedDefaults(_ location: CLLocation) {
        let defaults = SharedDefaults.suite
        defaults.set(location.coordinate.latitude, forKey: SharedDefaults.latitudeKey)
        defaults.set(location.coordinate.longitude, forKey: SharedDefaults.longitudeKey)
        defaults.set(Date().timeIntervalSince1970, forKey: SharedDefaults.locationTimestampKey)
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            Task { @MainActor [weak self] in
                guard let self, let placemark = placemarks?.first else { return }
                if let state = placemark.administrativeArea {
                    self.locationName = state
                } else if let city = placemark.locality {
                    self.locationName = city
                }
            }
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor [weak self] in
            guard let self, let loc = locations.last else { return }
            self.location = loc
            self.writeLocationToSharedDefaults(loc)
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
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }
}
