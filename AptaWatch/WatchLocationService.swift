import CoreLocation
import Combine

class WatchLocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?
    @Published var heading: Double = 0
    @Published var headingAccuracy: Double = -1

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        loadStoredLocation()
    }

    func reloadStoredLocation() {
        loadStoredLocation()
    }

    private func loadStoredLocation() {
        let lat = SharedDefaults.suite.double(forKey: SharedDefaults.latitudeKey)
        let lon = SharedDefaults.suite.double(forKey: SharedDefaults.longitudeKey)
        guard lat != 0 || lon != 0 else { return }
        location = CLLocation(latitude: lat, longitude: lon)
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func startHeading() {
        guard CLLocationManager.headingAvailable() else { return }
        manager.startUpdatingHeading()
    }

    func stopHeading() {
        manager.stopUpdatingHeading()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        location = loc
        SharedDefaults.suite.set(loc.coordinate.latitude, forKey: SharedDefaults.latitudeKey)
        SharedDefaults.suite.set(loc.coordinate.longitude, forKey: SharedDefaults.longitudeKey)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        // trueHeading requires a GPS fix; fall back to magneticHeading on GPS-less watches
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        headingAccuracy = newHeading.headingAccuracy
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Use stored location as fallback — already loaded in init
    }
}
