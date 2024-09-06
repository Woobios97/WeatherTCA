import SwiftUI
import ComposableArchitecture

struct WeatherView: View {
  let store: StoreOf<WeatherFeature>

  var body: some View {
    WithViewStore(self.store, observe: { $0 }) { viewStore in
      VStack {
        if viewStore.isLoading {
          ProgressView("Loading weather...")
        } else if viewStore.cities.isEmpty {
          Text("No cities added yet")
            .foregroundColor(.gray)
            .padding()
        } else {
          cityList(viewStore: viewStore)
        }
      }
      .onAppear {
        viewStore.send(.locationFeature(.requestLocationPermission))
      }
      .navigationTitle("Weather App")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          addButton(viewStore: viewStore)
        }
      }
      .alert(
        item: Binding(
          get: {
            viewStore.errorMessage.map { WeatherErrorWrapper(message: $0) }
          },
          set: { _ in viewStore.send(.setError(nil)) }
        )
      ) { weatherError in
        Alert(
          title: Text("Error"),
          message: Text(weatherError.message),
          dismissButton: .default(Text("OK"))
        )
      }
    }
  }

  private func cityList(viewStore: ViewStore<WeatherFeature.State, WeatherFeature.Action>) -> some View {
    List {
      ForEach(viewStore.cities) { city in
        cityRow(city: city)
      }
      .onDelete { indexSet in
        indexSet.forEach { index in
          viewStore.send(.removeCity(viewStore.cities[index].id))
        }
      }
    }
  }

  @ViewBuilder
  private func cityRow(city: CityWeather) -> some View {
    VStack(alignment: .leading) {
      Text(city.cityName)
        .font(.headline)
      if let temperature = city.temperature, let condition = city.condition {
        Text("\(temperature)° - \(condition)")
          .font(.subheadline)
      } else {
        Text("No weather data available")
          .font(.subheadline)
          .foregroundColor(.gray)
      }
    }
  }

  private func addButton(viewStore: ViewStore<WeatherFeature.State, WeatherFeature.Action>) -> some View {
    Button("Add City") {
      viewStore.send(.addCity("San Francisco, CA"))
    }
  }
}
