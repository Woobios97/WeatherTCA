import Foundation

enum WeatherError: Error, Equatable {
  case failedToFetchWeather(String)
  case locationNotFound(String)

  var localizedDescription: String {
    switch self {
    case .failedToFetchWeather(let message):
      return "Failed to fetch weather: \(message)"
    case .locationNotFound(let message):
      return "Location not found: \(message)"
    }
  }
}

enum LocationError: Error, Equatable {
  case noLocationFound
  case locationServicesDisabled

  var localizedDescription: String {
    switch self {
    case .noLocationFound:
      return "No location data found."
    case .locationServicesDisabled:
      return "Location services are disabled."
    }
  }
}
