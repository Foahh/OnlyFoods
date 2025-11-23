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

  @State private var selectedRestaurant: RestaurantModel?
  @State private var showSearchFilterView = false

  var body: some View {
    NavigationStack {
      ZStack {
        ClusteredMapView(
          restaurants: restaurants,
          reviews: reviews,
          onRestaurantSelected: { restaurant in
            selectedRestaurant = restaurant
          },
          onUserLocationUpdate: { location in
            searchService.userLocation = location
          }
        )
        .ignoresSafeArea(.all)
      }
      .navigationTitle("Map")
      .navigationBarTitleDisplayMode(.large)
      .overlay(alignment: .bottom) {
        SearchFilterButton(
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
    }
  }

  var restaurants: [RestaurantModel] {
    return restaurantService.restaurants
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

#Preview {
  MapTabView()
    .previewContainer()
}
