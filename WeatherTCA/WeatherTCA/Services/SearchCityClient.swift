import ComposableArchitecture
import MapKit
import CoreLocation

struct SearchCityClient {
  var searchCity: (String) async throws -> CLLocationCoordinate2D
}

extension SearchCityClient: DependencyKey {
  static let liveValue = Self(
    searchCity: { cityName in
      let request = MKLocalSearch.Request()
      request.naturalLanguageQuery = cityName

      let search = MKLocalSearch(request: request)
      let response = try await search.start()

      guard let coordinate = response.mapItems.first?.placemark.coordinate else {
        throw NSError(domain: "com.example.weather", code: 404, userInfo: [NSLocalizedDescriptionKey: "City not found"])
      }

      return coordinate
    }
  )
}

extension DependencyValues {
  var searchCity: SearchCityClient {
    get { self[SearchCityClient.self] }
    set { self[SearchCityClient.self] = newValue }
  }
}
