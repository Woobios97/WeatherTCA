import Foundation
import CoreLocation
import WeatherKit
import ComposableArchitecture

struct WeatherClient {
  var fetchWeather: (Double, Double) async throws -> CityWeather
}

extension WeatherClient: DependencyKey {
  static let liveValue = Self(
    fetchWeather: { latitude, longitude in
      let location = CLLocation(latitude: latitude, longitude: longitude)
      let weatherService = WeatherService.shared
      let weather = try await weatherService.weather(for: location)

      return CityWeather(
        cityName: "", // 이 부분은 실제 도시 이름으로 설정해야 합니다.
        latitude: latitude,
        longitude: longitude,
        temperature: weather.currentWeather.temperature.value,
        condition: weather.currentWeather.condition.description
      )
    }
  )
}

extension DependencyValues {
  var weatherClient: WeatherClient {
    get { self[WeatherClient.self] }
    set { self[WeatherClient.self] = newValue }
  }
}
