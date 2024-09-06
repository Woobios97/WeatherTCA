import ComposableArchitecture
import CoreLocation

@Reducer
struct LocationFeature {
  @ObservableState
  struct State: Equatable {
    var currentLocation: CLLocationCoordinate2D?
    var isRequestingLocation: Bool = false
    var errorMessage: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
  }

  enum Action: Equatable {
    case requestLocationPermission
    case locationPermissionGranted(CLAuthorizationStatus)
    case requestCurrentLocation
    case currentLocationReceived(Result<CLLocationCoordinate2D, LocationError>)
    case setError(String?)
  }

  @Dependency(\.locationManager) var locationManager
  @Dependency(\.mainQueue) var mainQueue

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .requestLocationPermission:
        state.errorMessage = nil
        return .run { send in
          locationManager.requestAuthorization()
          let status = locationManager.requestAuthorization
          await send(.locationPermissionGranted(status))
//          await send(.locationPermissionGranted(status))
        }

      case let .locationPermissionGranted(status):
        state.authorizationStatus = status
        if status == .authorizedWhenInUse || status == .authorizedAlways {
          return .send(.requestCurrentLocation)
        } else {
          state.errorMessage = "Location permission not granted."
          return .none
        }

      case .requestCurrentLocation:
        state.isRequestingLocation = true
        state.errorMessage = nil
        return .run { send in
          do {
            let coordinate = try await locationManager.requestCurrentLocation()
            await send(.currentLocationReceived(.success(coordinate)))
          } catch let error as LocationError {
            await send(.currentLocationReceived(.failure(error)))
          } catch {
            await send(.currentLocationReceived(.failure(.noLocationFound)))
          }
        }

      case let .currentLocationReceived(.success(coordinate)):
        state.currentLocation = coordinate
        state.isRequestingLocation = false
        return .none

      case let .currentLocationReceived(.failure(error)):
        state.errorMessage = error.localizedDescription
        state.isRequestingLocation = false
        return .none

      case let .setError(message):
        state.errorMessage = message
        return .none
      }
    }
  }
}
