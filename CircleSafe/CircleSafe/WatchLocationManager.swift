import Foundation
import CoreLocation
import Observation

@MainActor
@Observable
final class WatchLocationManager: NSObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    var location: CLLocation?

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
    }

    func start() {
        print("LOCATION MANAGER START")
        print("Authorization:", manager.authorizationStatus.rawValue)

        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func stop() {
        print("LOCATION MANAGER STOP")

        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        print(
            "LOCATION AUTH CHANGED:",
            manager.authorizationStatus.rawValue
        )

        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {

            manager.startUpdatingLocation()
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else {
            return
        }

        location = latest

        print(
            "LOCATION RECEIVED:",
            latest.coordinate.latitude,
            latest.coordinate.longitude
        )
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("LOCATION ERROR:", error)
    }
}
