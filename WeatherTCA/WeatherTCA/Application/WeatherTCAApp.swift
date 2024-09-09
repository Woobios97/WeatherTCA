import ComposableArchitecture
import SwiftUI
import SwiftData

class ModelContainerManager: ObservableObject {
  @Published var modelContainer: ModelContainer?

  init() {
    setupModelContainer()
  }

  private func setupModelContainer() {
    do {
      let container = try ModelContainer(for: CityWeather.self)
      self.modelContainer = container
      print("Model container successfully set up.")
    } catch {
      print("Failed to set up the model container: \(error.localizedDescription)")
      print("Detailed error: \(error)")
    }
  }
}

@main
struct WeatherTCAApp: App {
  @StateObject private var modelContainerManager = ModelContainerManager()

  var body: some Scene {
    WindowGroup {
      if let modelContainer = modelContainerManager.modelContainer {
        ContentView()
          .modelContainer(modelContainer)
      } else {
        Text("Failed to load data.")
      }
    }
  }
}

struct ContentView: View {
  static let store = Store(initialState: WeatherFeature.State()) {
    WeatherFeature()
  }

  @State private var navigationPath = NavigationPath()

  var body: some View {
    NavigationStack(path: $navigationPath) {
      WeatherView(store: ContentView.store)
    }
  }
}
