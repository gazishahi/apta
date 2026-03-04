import Foundation

enum SharedDefaults {
    static let suiteName = "group.Gazi.apta"

    static var suite: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    // Keys for shared location data
    static let latitudeKey = "shared_latitude"
    static let longitudeKey = "shared_longitude"
    static let locationTimestampKey = "shared_location_timestamp"
}
