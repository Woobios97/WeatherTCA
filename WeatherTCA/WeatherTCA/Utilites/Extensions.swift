import ComposableArchitecture
import SwiftUI
import CoreLocation

// Extensions.swift에 Equatable 확장을 추가
extension CLLocationCoordinate2D: Equatable {
  public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
  }
}
