import CoreLocation
import MapKit
import ComposableArchitecture

struct LocationManager {
  var requestCurrentLocation: () async throws -> CLLocationCoordinate2D
  var searchCity: (String) async throws -> CLLocationCoordinate2D
  var requestAuthorization: () -> CLAuthorizationStatus
  var locationServicesEnabled: () -> Bool
}

extension LocationManager: DependencyKey {
  static let liveValue = Self(
    requestCurrentLocation: {
      let manager = CLLocationManager()
      let delegate = LocationManagerDelegate()

      manager.delegate = delegate
      manager.requestWhenInUseAuthorization()

      guard CLLocationManager.locationServicesEnabled() else {
        throw LocationError.locationServicesDisabled
      }

      return try await withCheckedThrowingContinuation { continuation in
        delegate.didUpdateLocations = { locations in
          if let location = locations.first {
            continuation.resume(returning: location.coordinate)
          } else {
            continuation.resume(throwing: LocationError.noLocationFound)
          }
        }

        delegate.didFailWithError = { error in
          continuation.resume(throwing: error)
        }

        manager.requestLocation()
      }
    },
    searchCity: { cityName in
      let request = MKLocalSearch.Request()
      request.naturalLanguageQuery = cityName
      let search = MKLocalSearch(request: request)
      let response = try await search.start()

      if let coordinate = response.mapItems.first?.placemark.coordinate {
        return coordinate
      } else {
        throw LocationError.noLocationFound
      }
    },
    requestAuthorization: {
      let manager = CLLocationManager()
      manager.requestWhenInUseAuthorization()
      return manager.authorizationStatus
    },
    locationServicesEnabled: {
      return CLLocationManager.locationServicesEnabled()
    }
  )
}

extension DependencyValues {
  var locationManager: LocationManager {
    get { self[LocationManager.self] }
    set { self[LocationManager.self] = newValue }
  }
}

private class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
  var didUpdateLocations: (([CLLocation]) -> Void)?
  var didFailWithError: ((Error) -> Void)?

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    didUpdateLocations?(locations)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    didFailWithError?(error)
  }
}
