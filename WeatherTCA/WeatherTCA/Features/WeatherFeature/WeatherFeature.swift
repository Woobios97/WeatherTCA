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
        return weatherClient
          .fetchWeather(city.latitude, city.longitude)
          .receive(on: mainQueue)
          .catchToEffect()
          .map(Action.weatherFetched)

      case let .weatherFetched(.success(cityWeather)):
        state.cities.append(cityWeather)
        state.isLoading = false
        return .none

      case let .weatherFetched(.failure(error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      case let .setError(message):
        state.errorMessage = message
        return .none

      default:
        return .none
      }
    }
  }
}
