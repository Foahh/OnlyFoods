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
  @StateObject private var searchService = SearchService.shared

  //  private let initialRegion = MKCoordinateRegion(
  //			center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
  //			span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02) // smaller = more zoom in
  //		)

  var isTooZoomedOut: Bool {
    guard let region = visibleRegion else { return false }
    return region.span.latitudeDelta > 0.05
  }

  @State private var locationManager = LocationManager()
  @State private var visibleRegion: MKCoordinateRegion?
  @State private var selectedRestaurant: RestaurantModel?
  @State private var cameraPosition: MapCameraPosition = .automatic

  var filteredRestaurants: [RestaurantModel] {
    var filtered = restaurantService.restaurants

    if let region = visibleRegion {
      if region.span.latitudeDelta > 0.05 {
        return []  // 或之後改成顯示「Zoom in to see restaurants」
      }

      let center = region.center
      let span = region.span

      let minLat = center.latitude - span.latitudeDelta / 2
      let maxLat = center.latitude + span.latitudeDelta / 2
      let minLon = center.longitude - span.longitudeDelta / 2
      let maxLon = center.longitude + span.longitudeDelta / 2

      filtered = filtered.filter { restaurant in
        restaurant.latitude >= minLat && restaurant.latitude <= maxLat
          && restaurant.longitude >= minLon && restaurant.longitude <= maxLon
      }
    }

    if !searchService.searchText.isEmpty {
      filtered = filtered.filter { restaurant in
        restaurant.name.localizedCaseInsensitiveContains(searchService.searchText)
          || restaurant.categories.contains {
            $0.localizedCaseInsensitiveContains(searchService.searchText)
          }
      }
    }

    if let category = searchService.selectedCategory {
      filtered = filtered.filter { $0.categories.contains(category) }
    }

    let maxPins = 50
    if filtered.count > maxPins {
      filtered = Array(filtered.prefix(maxPins))
    }

    return filtered
  }

  func rating(for restaurant: RestaurantModel) -> RestaurantRating {
    restaurant.rating(from: reviews)
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Map(position: $cameraPosition) {
          ForEach(filteredRestaurants) { restaurant in
            let restaurantRating = rating(for: restaurant)
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
                  if restaurantRating.averageRating >= 1.0 {
                    Text(String(format: "%.1f", restaurantRating.averageRating))
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
        }
        .onMapCameraChange(frequency: .continuous) { context in
          visibleRegion = context.region
        }
        .onAppear {
          if visibleRegion == nil {
            let region = locationManager.region
            visibleRegion = region
            cameraPosition = .region(region)
          }
        }
        if isTooZoomedOut {
          VStack {
            Text("Please zoom in to view restaurants")
              .font(.callout)
              .padding(8)
              .background(.thinMaterial)
              .cornerRadius(12)
              .padding(.top, 12)
            Spacer()
          }
          .padding(.horizontal)
        }
      }
      .navigationTitle("Map")
      .sheet(item: $selectedRestaurant) { restaurant in
        RestaurantDetailView(restaurant: restaurant)
      }
    }
  }
}

#Preview {
  MapTabView()
    .previewContainer()
}
