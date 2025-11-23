//
//  ExploreTabView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftData
import SwiftUI

struct ExploreTabView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var reviews: [ReviewModel]
  @Query private var users: [UserModel]
  @StateObject private var restaurantService = RestaurantService.shared
  @StateObject private var timeService = TimeService.shared
  @State private var displayedRestaurants: [RestaurantModel] = []

  var body: some View {
    NavigationStack {
      ZStack {
        if restaurantService.isLoading {
          ProgressView()
            .scaleEffect(1.5)
        } else if displayedRestaurants.isEmpty {
          ExploreEmptyStateView(hasActiveFilters: false)
        } else {
          ScrollView {
            LazyVStack(spacing: 16) {
              ForEach(displayedRestaurants) { restaurant in
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
          .refreshable {
            await refreshRestaurants()
          }
        }
      }
      .navigationTitle("Explore")
      .navigationBarTitleDisplayMode(.large)
      .onAppear {
        processRestaurants()
      }
      .onChange(of: restaurantService.restaurants.count) { _, _ in
        if !restaurantService.isLoading {
          processRestaurants()
        }
      }
      .onChange(of: restaurantService.isLoading) { _, newValue in
        if !newValue {
          processRestaurants()
        }
      }
    }
  }

  private func processRestaurants() {
    guard !restaurantService.restaurants.isEmpty else {
      displayedRestaurants = []
      return
    }

    // Randomize restaurants
    var randomized = restaurantService.restaurants.shuffled()

    // Sort by open status (open first, closed second)
    randomized.sort { restaurant1, restaurant2 in
      let isOpen1 = restaurant1.isOpen(at: timeService.currentTime)
      let isOpen2 = restaurant2.isOpen(at: timeService.currentTime)
      return isOpen1 && !isOpen2
    }

    displayedRestaurants = randomized
  }

  private func refreshRestaurants() async {
    restaurantService.loadRestaurants()
    // Wait for loading to complete
    while restaurantService.isLoading {
      try? await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
    }
    processRestaurants()
  }
}

struct ExploreEmptyStateView: View {
  let hasActiveFilters: Bool

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: hasActiveFilters ? "magnifyingglass" : "fork.knife")
        .font(.system(size: 64))
        .foregroundStyle(.secondary.opacity(0.5))

      VStack(spacing: 8) {
        Text(hasActiveFilters ? "No restaurants found" : "No restaurants yet")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text(
          hasActiveFilters
            ? "Try adjusting your search or filters" : "Check back later for new restaurants"
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

struct RestaurantCardView: View {
  let restaurant: RestaurantModel
  let reviews: [ReviewModel]
  let users: [UserModel]
  @StateObject private var timeService = TimeService.shared

  var isOpenNow: Bool {
    restaurant.isOpen(at: timeService.currentTime)
  }

  var rating: RestaurantRating {
    restaurant.rating(from: reviews)
  }

  private var priceText: String? {
    guard let level = restaurant.priceLevel, level > 0 else { return nil }
    return String(repeating: "$", count: level)
  }

  private var favoriteCount: Int {
    RestaurantService.shared.getFavoriteCount(for: restaurant.id, from: users)
  }

  private var visitedCount: Int {
    RestaurantService.shared.getVisitedCount(for: restaurant.id, from: users)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Restaurant Image
      ZStack(alignment: .topTrailing) {
        RestaurantImageView(restaurant: restaurant)
          .frame(height: 200)
          .clipped()

        // Status Badge
        StatusBadge(isOpen: isOpenNow)
          .padding(12)
      }

      // Content
      VStack(alignment: .leading, spacing: 12) {
        // Name and Rating
        VStack(alignment: .leading, spacing: 8) {
          Text(restaurant.name)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.primary)
            .lineLimit(2)

          RatingView(rating: rating)
        }

        // Favorite/Visited Counts
        HStack(spacing: 16) {
          HStack(spacing: 4) {
            Image(systemName: favoriteCount > 0 ? "heart.fill" : "heart")
              .font(.caption)
              .foregroundStyle(favoriteCount > 0 ? .red : .secondary.opacity(0.5))
            if favoriteCount > 0 {
              Text("\(favoriteCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
              Text("No favorites yet")
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.6))
                .italic()
            }
          }

          HStack(spacing: 4) {
            Image(systemName: visitedCount > 0 ? "checkmark.circle.fill" : "checkmark.circle")
              .font(.caption)
              .foregroundStyle(visitedCount > 0 ? .blue : .secondary.opacity(0.5))
            if visitedCount > 0 {
              Text("\(visitedCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
              Text("No visits yet")
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.6))
                .italic()
            }
          }
        }

        // Categories
        if !restaurant.categories.isEmpty {
          CategoryChipsView(
            categories: Array(restaurant.categories.prefix(3)),
            priceText: priceText
          )
        }
      }
      .padding(16)
    }
    .background(Color(.systemBackground))
    .cornerRadius(16)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color(.separator), lineWidth: 0.5)
    )
    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
  }
}

struct RestaurantImageView: View {
  let restaurant: RestaurantModel

  var body: some View {
    Group {
      if let imageURL = restaurant.primaryImageURL {
        AsyncImage(url: imageURL) { phase in
          switch phase {
          case .empty:
            ImagePlaceholder()
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          case .failure:
            ImagePlaceholder()
          @unknown default:
            ImagePlaceholder()
          }
        }
      } else {
        ImagePlaceholder()
      }
    }
  }
}

#Preview {
  ExploreTabView()
    .previewContainer(withMockData: true)
}
