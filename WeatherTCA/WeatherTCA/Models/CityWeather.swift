import Foundation
import SwiftData

@Model
class CityWeather: Equatable {
  @Attribute(.unique) var id: UUID = UUID()
  var cityName: String
  var latitude: Double
  var longitude: Double
  var temperature: Double?
  var condition: String?

  init(
    cityName: String,
    latitude: Double,
    longitude: Double,
    temperature: Double? = nil,
    condition: String? = nil
  ) {
    self.cityName = cityName
    self.latitude = latitude
    self.longitude = longitude
    self.temperature = temperature
    self.condition = condition
  }
}
