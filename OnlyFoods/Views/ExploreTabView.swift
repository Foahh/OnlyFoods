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
  @StateObject private var searchService = SearchService.shared
  @StateObject private var timeService = TimeService.shared

  var filteredRestaurants: [RestaurantModel] {
    var filtered = restaurantService.restaurants

    if !searchService.searchText.isEmpty {
      filtered = filtered.filter { restaurant in
        restaurant.name.localizedCaseInsensitiveContains(searchService.searchText)
          || restaurant.categories.contains {
            $0.localizedCaseInsensitiveContains(searchService.searchText)
          }
      }
    }

    if let category = searchService.selectedCategory {
      filtered = filtered.filter { $0.categories.contains(category) }
    }

    return filtered
  }

  var body: some View {
    NavigationStack {
      ZStack {
        if restaurantService.isLoading {
          ProgressView()
            .scaleEffect(1.5)
        } else if filteredRestaurants.isEmpty {
          EmptyStateView(
            hasActiveFilters: !searchService.searchText.isEmpty
              || searchService.selectedCategory != nil
          )
        } else {
          ScrollView {
            LazyVStack(spacing: 16) {
              ForEach(filteredRestaurants) { restaurant in
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
            restaurantService.loadRestaurants()
          }
        }
      }
      .navigationTitle("Explore")
      .navigationBarTitleDisplayMode(.large)
    }
  }
}

struct EmptyStateView: View {
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
      if let doorImage = restaurant.doorImage, let doorImageURL = URL(string: doorImage) {
        AsyncImage(url: doorImageURL) { phase in
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
      } else if let firstImage = restaurant.images.first,
        let firstImageURL = URL(string: firstImage)
      {
        AsyncImage(url: firstImageURL) { phase in
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

struct ImagePlaceholder: View {
  var body: some View {
    ZStack {
      LinearGradient(
        colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Image(systemName: "photo")
        .font(.system(size: 40))
        .foregroundStyle(.secondary.opacity(0.5))
    }
  }
}

struct StatusBadge: View {
  let isOpen: Bool

  var body: some View {
    HStack(spacing: 6) {
      Circle()
        .fill(isOpen ? Color.green : Color.red)
        .frame(width: 8, height: 8)

      Text(isOpen ? "Open" : "Closed")
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundStyle(isOpen ? .green : .red)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(
      Capsule()

    )
  }
}

struct RatingView: View {
  let rating: RestaurantRating

  var hasRatings: Bool {
    rating.reviewCount > 0
  }

  var body: some View {
    HStack(spacing: 6) {
      HStack(spacing: 2) {
        ForEach(0..<5, id: \.self) { index in
          let starValue = Double(index) + 1.0
          if hasRatings {
            if starValue <= rating.averageRating {
              Image(systemName: "star.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
            } else if starValue - 0.5 <= rating.averageRating {
              Image(systemName: "star.lefthalf.fill")
                .font(.caption)
                .foregroundStyle(.yellow)
            } else {
              Image(systemName: "star")
                .font(.caption)
                .foregroundStyle(.yellow.opacity(0.3))
            }
          } else {
            // Empty state: show grayed-out stars
            Image(systemName: "star")
              .font(.caption)
              .foregroundStyle(.secondary.opacity(0.3))
          }
        }
      }

      if hasRatings {
        Text(String(format: "%.1f", rating.averageRating))
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)

        Text("(\(rating.reviewCount))")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        Text("No ratings yet")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .italic()
      }
    }
  }
}

struct CategoryChipsView: View {
  let categories: [String]
  let priceText: String?

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        if let priceText = priceText {
          CategoryChip(text: priceText, isPrice: true)
        }

        ForEach(categories, id: \.self) { category in
          CategoryChip(text: category)
        }
      }
    }
  }
}

struct CategoryChip: View {
  let text: String
  var isPrice: Bool = false

  var body: some View {
    Text(text)
      .font(.caption)
      .fontWeight(.medium)
      .foregroundStyle(isPrice ? .orange : .secondary)
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(
        Capsule()
          .fill(isPrice ? Color.orange.opacity(0.1) : Color(.systemGray5))
      )
  }
}

#Preview {
  ExploreTabView()
    .previewContainerWithUserManager(withMockData: true)
}
