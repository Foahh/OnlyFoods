//
//  FavoritedRestaurantsView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import SwiftData
import SwiftUI

struct FavoritedRestaurantsView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var userManager: UserManager
  @Query private var reviews: [ReviewModel]
  @StateObject private var restaurantService = RestaurantService.shared

  private var currentUser: UserModel? {
    userManager.currentUser
  }

  var favoriteRestaurants: [RestaurantModel] {
    guard let user = currentUser else { return [] }
    return restaurantService.restaurants.filter { user.isFavorite(restaurantID: $0.id) }
  }

  var body: some View {
    ScrollView {
      if favoriteRestaurants.isEmpty {
        FavoritedRestaurantsEmptyState()
      } else {
        FavoriteRestaurantsList(
          restaurants: favoriteRestaurants,
          reviews: reviews
        )
      }
    }
    .navigationTitle("Favorited Restaurants")
    .navigationBarTitleDisplayMode(.large)
    .background(Color(.systemGroupedBackground))
  }
}

struct FavoritedRestaurantsEmptyState: View {
  var body: some View {
    EmptyStateView(
      icon: "heart.slash",
      title: "No favorites yet",
      message: "Start exploring and add restaurants to your favorites"
    )
  }
}

struct FavoriteRestaurantsList: View {
  let restaurants: [RestaurantModel]
  let reviews: [ReviewModel]

  var body: some View {
    LazyVStack(spacing: 16) {
      ForEach(restaurants) { restaurant in
        NavigationLink {
          RestaurantDetailView(restaurant: restaurant)
        } label: {
          FavoritedRestaurantRow(restaurant: restaurant, reviews: reviews)
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }
}

struct FavoritedRestaurantRow: View {
  let restaurant: RestaurantModel
  let reviews: [ReviewModel]

  var rating: RestaurantRating {
    restaurant.rating(from: reviews)
  }

  var body: some View {
    HStack(spacing: 16) {
      RestaurantThumbnailView(restaurant: restaurant)

      RestaurantInfoView(restaurant: restaurant, rating: rating)

      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.secondary.opacity(0.5))
    }
    .padding(16)
    .background(Color(.systemBackground))
    .cornerRadius(16)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color(.separator), lineWidth: 0.5)
    )
    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
  }
}

#Preview {
  NavigationStack {
    FavoritedRestaurantsView()
      .previewContainer()
  }
}
