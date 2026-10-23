import CoreLocation
import Foundation

/// Asks for location only to compute prayer times on-device.
/// Falls back to Makkah when permission is denied or not yet granted.
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let makkah = CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)

    @Published private(set) var current: CLLocationCoordinate2D?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var effectiveCoordinate: CLLocationCoordinate2D {
        current ?? Self.makkah
    }

    var hasLocation: Bool {
        current != nil
    }

    func start() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            if current == nil {
                manager.requestLocation()
            }
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let last = locations.last {
            current = last.coordinate
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep the Makkah fallback; nothing else to do.
    }
}
