//
//  MyReviewsView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import SwiftData
import SwiftUI

struct MyReviewsView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var userManager: UserManager
  @Query private var reviews: [ReviewModel]
  @StateObject private var restaurantService = RestaurantService.shared

  private var currentUser: UserModel? {
    userManager.currentUser
  }

  var userReviews: [ReviewModel] {
    guard let user = currentUser else { return [] }
    return reviews.filter { $0.userID == user.id }
      .sorted { $0.timestamp > $1.timestamp }
  }

  var body: some View {
    ScrollView {
      if userReviews.isEmpty {
        EmptyReviewsView()
      } else {
        ReviewListContent(
          reviews: userReviews,
          restaurantService: restaurantService
        )
      }
    }
    .navigationTitle("My Reviews")
    .navigationBarTitleDisplayMode(.large)
    .background(Color(.systemGroupedBackground))
  }
}

struct EmptyReviewsView: View {
  var body: some View {
    EmptyStateView(
      icon: "star.slash",
      title: "No reviews yet",
      message: "Share your dining experiences with the community"
    )
  }
}
struct ReviewListContent: View {
  let reviews: [ReviewModel]
  let restaurantService: RestaurantService

  var body: some View {
    LazyVStack(spacing: 16) {
      ForEach(reviews) { review in
        ReviewNavigationLink(
          review: review,
          restaurantService: restaurantService
        )
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
  }
}

struct ReviewNavigationLink: View {
  let review: ReviewModel
  let restaurantService: RestaurantService

  var body: some View {
    NavigationLink {
      Group {
        if let restaurant = restaurantService.getRestaurant(by: review.restaurantID) {
          RestaurantDetailView(restaurant: restaurant)
        } else {
          Text("Restaurant not found")
            .navigationTitle("Error")
        }
      }
    } label: {
      UserReviewRow(
        review: review,
        restaurants: restaurantService.restaurants
      )
    }
    .buttonStyle(.plain)
  }
}

struct UserReviewRow: View {
  let review: ReviewModel
  let restaurants: [RestaurantModel]

  var restaurant: RestaurantModel? {
    restaurants.first { $0.id == review.restaurantID }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if let restaurant = restaurant {
        RestaurantHeaderView(restaurantName: restaurant.name)
      }

      StarRatingView(rating: review.rating)

      if !review.comment.isEmpty {
        Text(review.comment)
          .font(.body)
          .foregroundStyle(.primary)
          .lineLimit(3)
          .fixedSize(horizontal: false, vertical: true)
      }

      ReviewTimestampView(timestamp: review.timestamp)
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.systemBackground))
    .cornerRadius(16)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color(.separator), lineWidth: 0.5)
    )
    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
  }
}

struct RestaurantHeaderView: View {
  let restaurantName: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: "fork.knife")
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(restaurantName)
        .font(.headline)
        .foregroundStyle(.primary)
      Spacer()
      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.secondary.opacity(0.5))
    }
  }
}

struct StarRatingView: View {
  let rating: Int

  var body: some View {
    HStack(spacing: 4) {
      ForEach(1...5, id: \.self) { star in
        Image(systemName: star <= rating ? "star.fill" : "star")
          .foregroundStyle(star <= rating ? .yellow : .gray.opacity(0.3))
          .font(.subheadline)
      }
    }
  }
}

struct ReviewTimestampView: View {
  let timestamp: Date

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "clock")
        .font(.caption2)
        .foregroundStyle(.secondary.opacity(0.7))
      Text(timestamp, style: .relative)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  NavigationStack {
    MyReviewsView()
      .previewContainer()
  }
}
