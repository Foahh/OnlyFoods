//
//  MapTabView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import MapKit
import SwiftData
import SwiftUI

struct MapTabView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var reviews: [ReviewModel]
  @StateObject private var restaurantService = RestaurantService.shared
  @State private var selectedRestaurant: RestaurantModel?
  @State private var cameraPosition: MapCameraPosition = .region(
    MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),  // Default to Hong Kong
      span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
  )
  @State private var showSearchView = false
  @State private var searchText = ""
  @State private var selectedCategory: String?

  var filteredRestaurants: [RestaurantModel] {
    var filtered = restaurantService.restaurants

    if !searchText.isEmpty {
      filtered = filtered.filter { restaurant in
        restaurant.name.localizedCaseInsensitiveContains(searchText)
          || restaurant.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
      }
    }

    if let category = selectedCategory {
      filtered = filtered.filter { $0.categories.contains(category) }
    }

    return filtered
  }

  func rating(for restaurant: RestaurantModel) -> RestaurantRating {
    restaurant.rating(from: reviews)
  }

  var body: some View {
    NavigationStack {
      Map(position: $cameraPosition) {
        ForEach(filteredRestaurants) { restaurant in
          Annotation(
            restaurant.name,
            coordinate: CLLocationCoordinate2D(
              latitude: restaurant.latitude,
              longitude: restaurant.longitude
            )
          ) {
            Button {
              selectedRestaurant = restaurant
            } label: {
              VStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                  .foregroundColor(.red)
                  .font(.title2)
                Text(String(format: "%.1f", rating(for: restaurant).averageRating))
                  .font(.caption2)
                  .fontWeight(.bold)
                  .padding(4)
                  .background(Color.white)
                  .cornerRadius(4)
                  .shadow(radius: 2)
              }
            }
          }
        }
      }
      .navigationTitle("Map")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showSearchView = true
          } label: {
            Image(systemName: "magnifyingglass")
          }
        }
      }
      .sheet(isPresented: $showSearchView) {
        SearchView(
          searchText: $searchText,
          selectedCategory: $selectedCategory,
          restaurants: restaurantService.restaurants
        )
      }
      .sheet(item: $selectedRestaurant) { restaurant in
        RestaurantDetailView(restaurant: restaurant)
      }
    }
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: ReviewModel.self, UserModel.self, configurations: config)

  return MapTabView()
    .modelContainer(container)
}
