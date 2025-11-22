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
    if favoriteRestaurants.isEmpty {
      ScrollView {
        FavoritedRestaurantsEmptyState()
          .padding(.top, 8)
      }
      .navigationTitle("Favorited Restaurants")
      .navigationBarTitleDisplayMode(.large)
      .background(Color(.systemGroupedBackground))
    } else {
      List {
        ForEach(favoriteRestaurants) { restaurant in
          NavigationLink {
            RestaurantDetailView(restaurant: restaurant)
          } label: {
            FavoritedRestaurantRow(restaurant: restaurant, reviews: reviews)
          }
          .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
              removeFavorite(restaurantID: restaurant.id)
            } label: {
              Label("Unfavorite", systemImage: "heart.slash")
            }
          }
        }
      }
      .listStyle(.insetGrouped)
      .padding(.top, 8)
      .navigationTitle("Favorited Restaurants")
      .navigationBarTitleDisplayMode(.large)
    }
  }

  private func removeFavorite(restaurantID: String) {
    guard let user = currentUser else { return }
    user.removeFavorite(restaurantID: restaurantID)
    try? modelContext.save()
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

struct FavoritedRestaurantRow: View {
  let restaurant: RestaurantModel
  let reviews: [ReviewModel]

  var rating: RestaurantRating {
    restaurant.rating(from: reviews)
  }

  var body: some View {
    HStack(spacing: 12) {
      RestaurantThumbnailView(restaurant: restaurant, size: 60, cornerRadius: 8)

      RestaurantInfoView(restaurant: restaurant, rating: rating)
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  NavigationStack {
    FavoritedRestaurantsView()
      .previewContainer()
  }
}
