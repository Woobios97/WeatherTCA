import ComposableArchitecture
import Foundation

@Reducer
struct WeatherFeature {
  @ObservableState
  struct State: Equatable {
    var cities: [CityWeather] = []
    var isLoading: Bool = false
    var errorMessage: String?
  }

  enum Action: Equatable {
    case addCity(String)
    case removeCity(UUID)
    case fetchWeather(CityWeather)
    case weatherFetched(Result<CityWeather, WeatherError>)
    case setError(String?)
  }

  @Dependency(\.weatherClient) var weatherClient
  @Dependency(\.locationManager) var locationManager
  @Dependency(\.mainQueue) var mainQueue

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addCity(let cityName):
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
          do {
            // 검색 시작을 알리는 로그 추가
            print("🔍 Searching for city: \(cityName)")

            let coordinate = try await locationManager.searchCity(cityName)

            // 검색 결과를 로그로 출력
            print("📍 Found coordinates for city \(cityName): \(coordinate)")

            let cityWeather = CityWeather(
              cityName: cityName,
              latitude: coordinate.latitude,
              longitude: coordinate.longitude
            )
            await send(.fetchWeather(cityWeather))
          } catch {
            print("❌ Failed to find location for city: \(cityName), error: \(error)")

            await send(.setError("Failed to find city location."))
            await send(.weatherFetched(.failure(.locationNotFound("Could not find location for city: \(cityName)"))))
          }
        }

      case .fetchWeather(let city):
        return .run { send in
          do {
            let fetchedCityWeather = try await weatherClient.fetchWeather(city.latitude, city.longitude)
            await send(.weatherFetched(.success(fetchedCityWeather)))
          } catch let error as WeatherError {
            await send(.weatherFetched(.failure(error)))
          } catch {
            await send(.weatherFetched(.failure(.failedToFetchWeather("Unexpected error: \(error.localizedDescription)"))))
          }
        }
        .animation()

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

      case let .setError(message):
        state.errorMessage = message
        return .none
      }
    }
  }
}
