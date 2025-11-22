//
//  SearchView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import CoreLocation
import MapKit
import SwiftData
import SwiftUI

struct SearchTabView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var reviews: [ReviewModel]
  @Query private var users: [UserModel]
  @StateObject private var searchService = SearchService()
  @StateObject private var restaurantService = RestaurantService.shared
  @StateObject private var timeService = TimeService.shared
  @State private var locationManager = LocationManager()
  @State private var showFilterSheet = false

  var foundRestaurants: [RestaurantModel] {
    guard searchService.hasActiveSearch else {
      return []
    }

    let filtered = RestaurantFilter.filter(
      restaurants: restaurantService.restaurants,
      searchService: searchService
    )
    return RestaurantSorter.sort(
      restaurants: filtered,
      sortOption: searchService.sortOption,
      sortDirection: searchService.sortDirection,
      searchService: searchService,
      restaurantService: restaurantService,
      reviews: reviews,
      users: users
    )
  }

  var restaurantCount: Int {
    foundRestaurants.count
  }

  var body: some View {
    NavigationStack {
      ZStack {
        if restaurantService.isLoading {
          SearchLoadingView()
        } else if foundRestaurants.isEmpty {
          SearchEmptyStateView(hasActiveSearch: searchService.hasActiveSearch)
        } else {
          RestaurantListView(
            restaurants: foundRestaurants,
            reviews: reviews,
            users: users,
            onRefresh: {
              restaurantService.loadRestaurants()
            }
          )
        }
      }
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.large)
      .searchable(text: $searchService.searchText, prompt: "Search restaurants...")
      // It not recommended to use liquid glass button by apple here, since this element is layered below the TabBar.
      .overlay(alignment: .bottom) {
        FilterFloatingButton(
          restaurantCount: restaurantCount,
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
      .onAppear {
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

struct SearchLoadingView: View {
  var body: some View {
    ProgressView()
      .scaleEffect(1.5)
  }
}

struct RestaurantListView: View {
  let restaurants: [RestaurantModel]
  let reviews: [ReviewModel]
  let users: [UserModel]
  let onRefresh: () -> Void

  var body: some View {
    ScrollView {
      VStack(spacing: 16) {
        LazyVStack(spacing: 16) {
          ForEach(restaurants) { restaurant in
            NavigationLink {
              RestaurantDetailView(restaurant: restaurant)
            } label: {
              RestaurantCardView(restaurant: restaurant, reviews: reviews, users: users)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
      }
    }
    .refreshable {
      onRefresh()
    }
  }
}

struct SearchEmptyStateView: View {
  let hasActiveSearch: Bool

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: hasActiveSearch ? "magnifyingglass" : "fork.knife")
        .font(.system(size: 64))
        .foregroundStyle(.secondary.opacity(0.5))

      VStack(spacing: 8) {
        Text(hasActiveSearch ? "No restaurants found" : "Start searching")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text(
          hasActiveSearch
            ? "Try adjusting your search or filters" : "Search for restaurants by name or category"
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding()
  }
}

#Preview {
  SearchTabView()
    .previewContainer()
}
