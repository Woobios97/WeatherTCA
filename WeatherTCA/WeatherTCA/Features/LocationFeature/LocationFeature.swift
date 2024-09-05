import ComposableArchitecture
import CoreLocation

@Reducer
struct LocationFeature {
  @ObservableState
  struct State: Equatable {
    var currentLocation: CLLocationCoordinate2D?
    var isRequestingLocation: Bool = false
    var errorMessage: String?
  }

  enum Action: Equatable {
    case requestCurrentLocation
    case currentLocationReceived(Result<CLLocationCoordinate2D, LocationError>)
    case searchCity(String)
    case cityCoordinateReceived(Result<CLLocationCoordinate2D, LocationError>)
    case setError(String?)
  }

  @Dependency(\.locationManager) var locationManager
  @Dependency(\.mainQueue) var mainQueue

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .requestCurrentLocation:
        state.isRequestingLocation = true
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

      case let .searchCity(cityName):
        state.isRequestingLocation = true
        state.errorMessage = nil
        return .run { send in
          do {
            let coordinate = try await locationManager.searchCity(cityName)
            await send(.cityCoordinateReceived(.success(coordinate)))
          } catch let error as LocationError {
            await send(.cityCoordinateReceived(.failure(error)))
          } catch {
            await send(.cityCoordinateReceived(.failure(.noLocationFound)))
          }
        }

      case let .cityCoordinateReceived(.success(coordinate)):
        state.currentLocation = coordinate
        state.isRequestingLocation = false
        return .none

      case let .cityCoordinateReceived(.failure(error)):
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

