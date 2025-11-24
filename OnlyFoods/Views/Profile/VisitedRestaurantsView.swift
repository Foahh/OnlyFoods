//
//  VisitedRestaurantsView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import SwiftData
import SwiftUI

struct VisitedRestaurantsView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var userManager: UserManager
  @Query private var reviews: [ReviewModel]
  @StateObject private var restaurantService = RestaurantService.shared

  private var currentUser: UserModel? {
    userManager.currentUser
  }

  var visitedRestaurants: [RestaurantModel] {
    guard let user = currentUser else { return [] }
    return restaurantService.restaurants.filter { user.isVisited(restaurantID: $0.id) }
  }

  var body: some View {
    if visitedRestaurants.isEmpty {
      ScrollView {
        VisitedRestaurantsEmptyState()
          .padding(.top, 8)
      }
      .navigationTitle("Visited Restaurants")
      .navigationBarTitleDisplayMode(.large)
      .background(Color(.systemGroupedBackground))
    } else {
      List {
        ForEach(visitedRestaurants) { restaurant in
          NavigationLink {
            RestaurantDetailView(restaurant: restaurant)
          } label: {
            VisitedRestaurantRow(restaurant: restaurant, reviews: reviews)
          }
          .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
              removeVisited(restaurantID: restaurant.id)
            } label: {
              Label("Unvisit", systemImage: "circle.slash")
            }
          }
        }
      }
      .listStyle(.insetGrouped)
      .padding(.top, 8)
      .navigationTitle("Visited Restaurants")
      .navigationBarTitleDisplayMode(.large)
    }
  }

  private func removeVisited(restaurantID: String) {
    guard let user = currentUser else { return }
    user.removeVisited(restaurantID: restaurantID)
    try? modelContext.save()
  }
}

struct VisitedRestaurantsEmptyState: View {
  var body: some View {
    EmptyStateView(
      icon: "checkmark.circle",
      title: "No visited restaurants yet",
      message: "Mark restaurants as visited to keep track of your dining experiences"
    )
  }
}

struct VisitedRestaurantRow: View {
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
    VisitedRestaurantsView()
      .previewContainer()
  }
}
