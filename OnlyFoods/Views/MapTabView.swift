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
  @State private var showSearchFilterView = false

  var body: some View {
    NavigationStack {
      ZStack {
        MapContent(
          restaurants: restaurants,
          cameraPosition: $cameraPosition,
          visibleRegion: $visibleRegion,
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
        SearchFilterButton(
          isMap: true,
          restaurantCount: restaurants.count,
          hasActiveSearch: searchService.hasActiveSearch,
          action: { showSearchFilterView = true }
        ).padding(.bottom, 20)
      }
      .sheet(isPresented: $showSearchFilterView) {
        SearchFilterView(
          searchService: searchService,
          restaurantService: restaurantService,
          showSortSection: false,
          showDistanceSection: false
        )
      }
      .sheet(item: $selectedRestaurant) { restaurant in
        NavigationStack {
          RestaurantDetailView(restaurant: restaurant)
            .toolbar {
              ToolbarItem(placement: .navigationBarLeading) {
                Button {
                  selectedRestaurant = nil
                } label: {
                  Image(systemName: "chevron.left")
                }
              }
            }
        }
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

  var restaurants: [RestaurantModel] {
    return restaurantService.restaurants
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
      // Update visible region immediately for smooth UI
      visibleRegion = context.region
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
            .font(.system(size: 8, weight: .semibold))
            .foregroundStyle(.white)
          Text(String(format: "%.1f", rating.averageRating))
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
          Capsule()
            .fill(pinColor)
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
        )
        .offset(y: -1)
      }

      // Pin icon
      Image(systemName: "mappin.circle.fill")
        .font(.system(size: 20, weight: .medium))
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
