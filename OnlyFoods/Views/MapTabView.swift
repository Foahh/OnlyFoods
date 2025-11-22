//  MapTabView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct MapTabView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var reviews: [ReviewModel]
  @Query private var users: [UserModel]
  @StateObject private var searchService = SearchService()
  @StateObject private var restaurantService = RestaurantService.shared

  var isTooZoomedOut: Bool {
    guard let region = visibleRegion else { return false }
    return region.span.latitudeDelta > 0.05
  }

  @State private var locationManager = LocationManager()
  @State private var visibleRegion: MKCoordinateRegion?
  @State private var selectedRestaurant: RestaurantModel?
  @State private var cameraPosition: MapCameraPosition = .automatic
  @State private var showFilterSheet = false

  var filteredRestaurants: [RestaurantModel] {
    var filtered = restaurantService.restaurants

    // Apply search service filters
    filtered = RestaurantFilter.filter(
      restaurants: filtered,
      searchService: searchService
    )

    // Apply map region filter
    if let region = visibleRegion {
      if region.span.latitudeDelta > 0.05 {
        return []
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

    // Apply sorting
    filtered = RestaurantSorter.sort(
      restaurants: filtered,
      sortOption: searchService.sortOption,
      sortDirection: searchService.sortDirection,
      searchService: searchService,
      restaurantService: restaurantService,
      reviews: reviews,
      users: users
    )

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
      .overlay(alignment: .bottom) {
        FilterFloatingButton(
          restaurantCount: filteredRestaurants.count,
          hasActiveFilters: searchService.hasActiveFilters,
          action: { showFilterSheet = true }
        )
      }
      .sheet(isPresented: $showFilterSheet) {
        FilterSheet(
          searchService: searchService,
          restaurantService: restaurantService
        )
      }
      .sheet(item: $selectedRestaurant) { restaurant in
        RestaurantDetailView(restaurant: restaurant)
      }
      .onAppear {
        if visibleRegion == nil {
          let region = locationManager.region
          visibleRegion = region
          cameraPosition = .region(region)
        }
        updateUserLocation()
      }
      .onChange(of: locationManager.region.center.latitude) { _, _ in
        updateUserLocation()
      }
      .onChange(of: locationManager.region.center.longitude) { _, _ in
        updateUserLocation()
      }
    }
  }

  private func updateUserLocation() {
    let center = locationManager.region.center
    searchService.userLocation = CLLocation(
      latitude: center.latitude,
      longitude: center.longitude
    )
  }
}

#Preview {
  MapTabView()
    .previewContainer()
}
