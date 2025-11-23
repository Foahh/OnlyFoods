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
  @State private var debouncedRegion: MKCoordinateRegion?
  @State private var debounceTask: Task<Void, Never>?
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
          debouncedRegion: $debouncedRegion,
          debounceTask: $debounceTask,
          reviews: reviews,
          onRestaurantSelected: { restaurant in
            selectedRestaurant = restaurant
          },
        )

        MapOverlays(
          isLoading: restaurantService.isLoading
        )
      }
      .navigationTitle("Map")
      .navigationBarTitleDisplayMode(.large)
      .overlay(alignment: .bottom) {
        FilterFloatingButton(
          isMap: true,
          restaurantCount: filteredRestaurants.count,
          hasActiveSearch: searchService.hasActiveSearch,
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

  var filteredRestaurants: [RestaurantModel] {
    MapRestaurantFilter.filter(
      restaurants: restaurantService.restaurants,
      visibleRegion: debouncedRegion ?? visibleRegion,
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
      debouncedRegion = region
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
  @Binding var debouncedRegion: MKCoordinateRegion?
  @Binding var debounceTask: Task<Void, Never>?
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
      // Update visible region immediately for smooth UI
      visibleRegion = context.region

      // Debounce the region update for filtering
      debounceTask?.cancel()
      debounceTask = Task {
        try? await Task.sleep(nanoseconds: 300_000_000)  // 300ms debounce
        if !Task.isCancelled {
          await MainActor.run {
            debouncedRegion = context.region
          }
        }
      }
    }
  }
}

struct MapOverlays: View {
  let isLoading: Bool

  var body: some View {
    if isLoading {
      MapLoadingOverlay()
    }
  }
}

struct MapRestaurantFilter {
  // Adaptive pin limits based on zoom level
  // More pins when zoomed in, fewer when zoomed out
  private static func getMaxPins(for region: MKCoordinateRegion?) -> Int {
    guard let region = region else { return 30 }
    let span = region.span.latitudeDelta

    // Level 1: Extremely zoomed out (country/continent view)
    if span > 0.5 { return 15 }
    // Level 2: Very zoomed out (region view)
    if span > 0.2 { return 25 }
    // Level 3: Zoomed out (city-wide view)
    if span > 0.1 { return 35 }
    // Level 4: Moderately zoomed out (district view)
    if span > 0.05 { return 50 }
    // Level 5: Medium zoom (neighborhood view)
    if span > 0.025 { return 75 }
    // Level 6: Zoomed in (street block view)
    if span > 0.01 { return 100 }
    // Level 7: Very zoomed in (multiple buildings)
    if span > 0.005 { return 150 }
    // Level 8: Extremely zoomed in (single building area)
    if span > 0.002 { return 250 }
    // Level 9: Ultra zoomed in (building level)
    if span > 0.001 { return 400 }
    // Level 10: Maximum zoom (show all visible)
    return 1000
  }

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

    // Prioritize and limit pins (adaptive limits handle zoom level)
    guard let region = visibleRegion else {
      return []
    }

    // Prioritize and limit pins
    return prioritizeAndLimit(
      restaurants: filtered,
      region: region,
      maxPins: getMaxPins(for: region),
      searchService: searchService,
      restaurantService: restaurantService,
      reviews: reviews,
      users: users
    )
  }

  private static func applyRegionFilter(
    _ restaurants: [RestaurantModel],
    region: MKCoordinateRegion?
  ) -> [RestaurantModel] {
    guard let region = region else { return restaurants }

    let center = region.center
    let span = region.span

    // Add padding to region to show restaurants near the edge
    let padding = 1.2
    let minLat = center.latitude - span.latitudeDelta / 2 * padding
    let maxLat = center.latitude + span.latitudeDelta / 2 * padding
    let minLon = center.longitude - span.longitudeDelta / 2 * padding
    let maxLon = center.longitude + span.longitudeDelta / 2 * padding

    return restaurants.filter { restaurant in
      restaurant.latitude >= minLat && restaurant.latitude <= maxLat
        && restaurant.longitude >= minLon && restaurant.longitude <= maxLon
    }
  }

  /// Prioritizes restaurants based on rating, distance, and popularity, then applies spatial clustering
  private static func prioritizeAndLimit(
    restaurants: [RestaurantModel],
    region: MKCoordinateRegion,
    maxPins: Int,
    searchService: SearchService,
    restaurantService: RestaurantService,
    reviews: [ReviewModel],
    users: [UserModel]
  ) -> [RestaurantModel] {
    guard !restaurants.isEmpty else { return [] }

    // If we have fewer restaurants than the limit, return all
    guard restaurants.count > maxPins else {
      return applySpatialClustering(
        restaurants: restaurants,
        region: region,
        maxPins: maxPins
      )
    }

    // Calculate scores for each restaurant
    let scoredRestaurants = restaurants.map {
      restaurant -> (restaurant: RestaurantModel, score: Double) in
      let rating = restaurantService.getRatingDetails(
        for: restaurant.id,
        from: reviews
      )
      let favoriteCount = restaurantService.getFavoriteCount(
        for: restaurant.id,
        from: users
      )
      let visitedCount = restaurantService.getVisitedCount(
        for: restaurant.id,
        from: users
      )

      // Calculate composite score
      var score: Double = 0.0

      // Rating component (0-5 scale, weighted 40%)
      if rating.reviewCount > 0 {
        score += rating.averageRating * 0.4
        // Bonus for having more reviews (up to 0.5 points)
        score += min(Double(rating.reviewCount) / 20.0, 0.5) * 0.2
      }

      // Popularity component (favorites + visits, weighted 30%)
      let popularityScore = Double(favoriteCount * 2 + visitedCount) / 100.0
      score += min(popularityScore, 1.0) * 0.3

      // Distance component (weighted 30%) - closer is better
      if let userLocation = searchService.userLocation {
        let distance = DistanceCalculator.distance(
          from: userLocation,
          to: restaurant.coordinate
        )
        // Normalize distance: 0-2km maps to 1.0-0.0 score
        let distanceScore = max(0, 1.0 - (distance / 2000.0))
        score += distanceScore * 0.3
      } else {
        // If no user location, give neutral score
        score += 0.15
      }

      return (restaurant: restaurant, score: score)
    }

    // Sort by score (descending) and take top candidates
    let topCandidates =
      scoredRestaurants
      .sorted { $0.score > $1.score }
      .prefix(maxPins * 2)  // Get 2x candidates for clustering
      .map { $0.restaurant }

    // Apply spatial clustering to avoid overlapping pins
    return applySpatialClustering(
      restaurants: Array(topCandidates),
      region: region,
      maxPins: maxPins
    )
  }

  /// Applies spatial clustering to prevent overlapping pins
  /// Groups nearby restaurants and selects the best one from each cluster
  private static func applySpatialClustering(
    restaurants: [RestaurantModel],
    region: MKCoordinateRegion,
    maxPins: Int
  ) -> [RestaurantModel] {
    guard !restaurants.isEmpty else { return [] }

    // Adaptive cluster threshold based on zoom level (in degrees)
    // More zoomed in = smaller threshold = more clusters
    // Fine-tuned for better spatial distribution
    let span = region.span.latitudeDelta
    let clusterThreshold: Double
    if span > 0.1 {
      // Very zoomed out: larger clusters
      clusterThreshold = span * 0.08
    } else if span > 0.01 {
      // Medium zoom: moderate clusters
      clusterThreshold = span * 0.05
    } else if span > 0.002 {
      // Zoomed in: smaller clusters
      clusterThreshold = span * 0.03
    } else {
      // Very zoomed in: minimal clustering
      clusterThreshold = span * 0.02
    }

    var clusters: [[RestaurantModel]] = []
    var usedIndices = Set<Int>()

    for (index, restaurant) in restaurants.enumerated() {
      if usedIndices.contains(index) { continue }

      var cluster = [restaurant]
      usedIndices.insert(index)

      // Find nearby restaurants to cluster
      for (otherIndex, otherRestaurant) in restaurants.enumerated() {
        if usedIndices.contains(otherIndex) { continue }
        if index == otherIndex { continue }

        let latDiff = abs(restaurant.latitude - otherRestaurant.latitude)
        let lonDiff = abs(restaurant.longitude - otherRestaurant.longitude)

        // Simple distance check (approximate)
        if latDiff < clusterThreshold && lonDiff < clusterThreshold {
          cluster.append(otherRestaurant)
          usedIndices.insert(otherIndex)
        }
      }

      clusters.append(cluster)

      // Early exit if we have enough clusters
      if clusters.count >= maxPins {
        break
      }
    }

    // Select the first restaurant from each cluster (already sorted by priority)
    let result = clusters.prefix(maxPins).compactMap { $0.first }

    return Array(result)
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
