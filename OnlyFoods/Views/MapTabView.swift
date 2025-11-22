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

  @State private var locationManager = LocationManager()
  @State private var visibleRegion: MKCoordinateRegion?
  @State private var selectedRestaurant: RestaurantModel?
  @State private var cameraPosition: MapCameraPosition = .automatic
  @State private var showFilterSheet = false

  var body: some View {
    NavigationStack {
      ZStack {
        MapContent(
          restaurants: filteredRestaurants,
          cameraPosition: $cameraPosition,
          visibleRegion: $visibleRegion,
          reviews: reviews,
          onRestaurantSelected: { restaurant in
            selectedRestaurant = restaurant
          },
        )

        MapOverlays(
          isLoading: restaurantService.isLoading,
          isTooZoomedOut: isTooZoomedOut
        )
      }
      .navigationTitle("Map")
      .navigationBarTitleDisplayMode(.large)
      .overlay(alignment: .bottom) {
        FilterFloatingButton(
          restaurantCount: filteredRestaurants.count,
          hasActiveFilters: searchService.hasActiveFilters,
          action: { showFilterSheet = true }
        ).padding(.bottom, 20)
      }
      .sheet(isPresented: $showFilterSheet) {
        FilterSheet(
          searchService: searchService,
          restaurantService: restaurantService,
          showSortSection: false,
          showDistanceSection: false
        )
      }
      .sheet(item: $selectedRestaurant) { restaurant in
        RestaurantDetailView(restaurant: restaurant)
      }
      .onAppear {
        initializeMapRegion()
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

  var isTooZoomedOut: Bool {
    guard let region = visibleRegion else { return false }
    return region.span.latitudeDelta > 0.05
  }

  var filteredRestaurants: [RestaurantModel] {
    MapRestaurantFilter.filter(
      restaurants: restaurantService.restaurants,
      visibleRegion: visibleRegion,
      searchService: searchService,
      restaurantService: restaurantService,
      reviews: reviews,
      users: users
    )
  }

  private func initializeMapRegion() {
    if visibleRegion == nil {
      let region = locationManager.region
      visibleRegion = region
      cameraPosition = .region(region)
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

struct MapContent: View {
  let restaurants: [RestaurantModel]
  @Binding var cameraPosition: MapCameraPosition
  @Binding var visibleRegion: MKCoordinateRegion?
  let reviews: [ReviewModel]
  let onRestaurantSelected: (RestaurantModel) -> Void

  var body: some View {
    Map(position: $cameraPosition) {
      UserAnnotation()
      ForEach(restaurants) { restaurant in
        let restaurantRating = restaurant.rating(from: reviews)
        Annotation(
          restaurant.name,
          coordinate: CLLocationCoordinate2D(
            latitude: restaurant.latitude,
            longitude: restaurant.longitude
          )
        ) {
          MapPinView(rating: restaurantRating)
            .onTapGesture {
              let impactFeedback = UIImpactFeedbackGenerator(style: .light)
              impactFeedback.impactOccurred()
              onRestaurantSelected(restaurant)
            }
        }
      }
    }
    .mapStyle(.standard)
    .onMapCameraChange(frequency: .continuous) { context in
      visibleRegion = context.region
    }
  }
}

struct MapOverlays: View {
  let isLoading: Bool
  let isTooZoomedOut: Bool

  var body: some View {
    ZStack {
      if isLoading {
        MapLoadingOverlay()
      }

      if isTooZoomedOut {
        MapZoomWarningView()
      }
    }
  }
}

struct MapRestaurantFilter {
  static func filter(
    restaurants: [RestaurantModel],
    visibleRegion: MKCoordinateRegion?,
    searchService: SearchService,
    restaurantService: RestaurantService,
    reviews: [ReviewModel],
    users: [UserModel]
  ) -> [RestaurantModel] {
    var filtered = restaurants

    // Apply search service filters
    filtered = RestaurantFilter.filter(
      restaurants: filtered,
      searchService: searchService
    )

    // Apply map region filter
    filtered = applyRegionFilter(filtered, region: visibleRegion)

    // Limit to max pins
    return limitToMaxPins(filtered, maxPins: 50)
  }

  private static func applyRegionFilter(
    _ restaurants: [RestaurantModel],
    region: MKCoordinateRegion?
  ) -> [RestaurantModel] {
    guard let region = region else { return restaurants }

    // Return empty if too zoomed out
    if region.span.latitudeDelta > 0.05 {
      return []
    }

    let center = region.center
    let span = region.span

    let minLat = center.latitude - span.latitudeDelta / 2
    let maxLat = center.latitude + span.latitudeDelta / 2
    let minLon = center.longitude - span.longitudeDelta / 2
    let maxLon = center.longitude + span.longitudeDelta / 2

    return restaurants.filter { restaurant in
      restaurant.latitude >= minLat && restaurant.latitude <= maxLat
        && restaurant.longitude >= minLon && restaurant.longitude <= maxLon
    }
  }

  private static func limitToMaxPins(
    _ restaurants: [RestaurantModel],
    maxPins: Int
  ) -> [RestaurantModel] {
    guard restaurants.count > maxPins else { return restaurants }
    return Array(restaurants.prefix(maxPins))
  }
}

struct MapPinView: View {
  let rating: RestaurantRating

  private var pinColor: Color {
    guard rating.reviewCount > 0 else { return .gray }
    if rating.averageRating >= 4.0 {
      return .green
    } else if rating.averageRating >= 3.0 {
      return .orange
    } else {
      return .red
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Rating badge
      if rating.reviewCount > 0 {
        HStack(spacing: 3) {
          Image(systemName: "star.fill")
            .font(.system(size: 7, weight: .semibold))
            .foregroundStyle(.white)
          Text(String(format: "%.1f", rating.averageRating))
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
          Capsule()
            .fill(pinColor)
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        )
        .offset(y: -1)
      }

      // Pin icon
      Image(systemName: "mappin.circle.fill")
        .font(.system(size: 24, weight: .medium))
        .foregroundStyle(pinColor)
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
  }
}

struct MapZoomWarningView: View {
  @State private var isVisible = false

  var body: some View {
    VStack {
      HStack(spacing: 12) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.blue)
        VStack(alignment: .leading, spacing: 2) {
          Text("Zoom in to view restaurants")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.primary)
          Text("Pinch to zoom or use the controls")
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(.ultraThinMaterial)
          .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
      )
      .padding(.horizontal, 20)
      .padding(.top, 12)
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : -20)
      Spacer()
    }
    .onAppear {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1)) {
        isVisible = true
      }
    }
  }
}

struct MapLoadingOverlay: View {
  var body: some View {
    ZStack {
      Color(.systemBackground)
        .opacity(0.3)
        .ignoresSafeArea()

      VStack(spacing: 16) {
        ProgressView()
          .scaleEffect(1.2)
          .tint(.blue)
        Text("Loading restaurants...")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .padding(24)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(.ultraThinMaterial)
          .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
      )
    }
  }
}

extension View {
  func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
    self.simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in
          onPress()
        }
        .onEnded { _ in
          onRelease()
        }
    )
  }
}

#Preview {
  MapTabView()
    .previewContainer()
}
