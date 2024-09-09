import ComposableArchitecture
import SwiftUI

@Reducer
struct WeatherFeature {
  @ObservableState
  struct State: Equatable {
    var cities: [CityWeather] = []
    var isLoading: Bool = false
    var errorMessage: String?
    var locationFeature: LocationFeature.State = LocationFeature.State()
  }

  enum Action: Equatable {
    case locationFeature(LocationFeature.Action)
    case fetchWeather(CityWeather)
    case weatherFetched(Result<CityWeather, WeatherError>)
    case removeCity(UUID)
    case addCity(String)
    case setError(String?)
  }

  @Dependency(\.weatherClient) var weatherClient
  @Dependency(\.locationManager) var locationManager
  @Dependency(\.mainQueue) var mainQueue

  var body: some ReducerOf<Self> {
    Scope(state: \.locationFeature, action: /Action.locationFeature) {
      LocationFeature()
    }

    Reduce { state, action in
      switch action {
      case .locationFeature(.currentLocationReceived(.success(let coordinate))):
        state.isLoading = true
        return .run { send in
          let cityWeather = CityWeather(
            cityName: "Current Location",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
          )
          await send(.fetchWeather(cityWeather))
        }

      case let .fetchWeather(city):
        return .run { send in
          do {
            let cityWeather = try await weatherClient.fetchWeather(city.latitude, city.longitude)
            await send(.weatherFetched(.success(cityWeather)))
          } catch {
            let weatherError = WeatherError.failedToFetchWeather(error.localizedDescription)
            await send(.weatherFetched(.failure(weatherError)))
          }
        }

      case let .weatherFetched(.success(cityWeather)):
        state.cities.append(cityWeather)
        state.isLoading = false
        return .none

      case let .weatherFetched(.failure(error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      case let .removeCity(cityId):
        state.cities.removeAll { $0.id == cityId }
        return .none

      case let .addCity(cityName):
        state.isLoading = true
        return .run { send in
          do {
            let coordinate = try await locationManager.searchCity(cityName)
            let cityWeather = CityWeather(
              cityName: cityName,
              latitude: coordinate.latitude,
              longitude: coordinate.longitude
            )
            await send(.fetchWeather(cityWeather))
          } catch {
            await send(.setError("Failed to add city: \(cityName)"))
          }
        }

      case let .setError(message):
        state.errorMessage = message
        return .none

      default:
        return .none
      }
    }
  }
}
