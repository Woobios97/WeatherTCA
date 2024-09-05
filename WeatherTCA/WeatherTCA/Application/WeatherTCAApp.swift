import ComposableArchitecture
import SwiftUI
import SwiftData

@main
struct WeatherTCAApp: App {
  let store = Store(
    initialState: WeatherFeature.State(),
    reducer: {
      WeatherFeature()
    }
  )

  var body: some Scene {
    WindowGroup {
      WeatherView(store: store)
        .onAppear {
          // 앱이 시작될 때 초기화 작업을 수행할 수 있습니다.
          // 예를 들어, 초기 데이터를 로드하거나 사용자 권한을 요청할 수 있습니다.
        }
    }
  }
}
