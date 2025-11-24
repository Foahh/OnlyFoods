//
//  ProfileTabView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftData
import SwiftUI

struct ProfileTabView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var userManager: UserManager
  @Query private var users: [UserModel]
  @Query private var reviews: [ReviewModel]
  @StateObject private var restaurantService = RestaurantService.shared
  @State private var showAuthView = false

  private var currentUser: UserModel? {
    userManager.currentUser
  }

  var userReviews: [ReviewModel] {
    guard let user = currentUser else { return [] }
    return reviews.filter { $0.userID == user.id }
      .sorted { $0.timestamp > $1.timestamp }
  }

  var favoriteRestaurants: [RestaurantModel] {
    guard let user = currentUser else { return [] }
    return restaurantService.restaurants.filter { user.isFavorite(restaurantID: $0.id) }
  }

  var visitedRestaurants: [RestaurantModel] {
    guard let user = currentUser else { return [] }
    return restaurantService.restaurants.filter { user.isVisited(restaurantID: $0.id) }
  }

  var body: some View {
    NavigationStack {
      if let user = currentUser {
        ScrollView {
          VStack(spacing: 24) {
            ProfileHeaderView(user: user, reviewCount: userReviews.count)

            ProfileListsSection(
              visitedCount: visitedRestaurants.count,
              favoriteCount: favoriteRestaurants.count,
              reviewCount: userReviews.count
            )

            LogoutButton(action: { userManager.logout() })
          }
          .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
      } else {
        ProfileEmptyStateView(showAuthView: $showAuthView)
      }
    }
  }
}

struct ProfileHeaderView: View {
  let user: UserModel
  let reviewCount: Int

  var body: some View {
    VStack(spacing: 16) {
      Circle()
        .fill(Color.blue.opacity(0.75))
        .frame(width: 110, height: 110)
        .overlay {
          Image(systemName: "person.fill")
            .font(.system(size: 50))
            .foregroundColor(.white)
        }
      VStack(spacing: 4) {
        Text(user.username)
          .font(.title)
          .fontWeight(.bold)
          .foregroundStyle(.primary)
      }
    }
    .padding(.top, 8)
    .padding(.bottom, 8)
  }
}

struct ProfileListsSection: View {
  let visitedCount: Int
  let favoriteCount: Int
  let reviewCount: Int

  var body: some View {
    VStack(spacing: 12) {
      NavigationLink {
        VisitedRestaurantsView()
      } label: {
        ProfileListRow(
          title: "Visited Restaurants",
          icon: "checkmark.circle.fill",
          iconColor: .blue,
          count: visitedCount
        )
      }
      .buttonStyle(.plain)

      NavigationLink {
        FavoritedRestaurantsView()
      } label: {
        ProfileListRow(
          title: "Favorited Restaurants",
          icon: "heart.fill",
          iconColor: .orange,
          count: favoriteCount
        )
      }
      .buttonStyle(.plain)

      NavigationLink {
        MyReviewsView()
      } label: {
        ProfileListRow(
          title: "My Reviews",
          icon: "star.fill",
          iconColor: .blue,
          count: reviewCount
        )
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
  }
}

struct LogoutButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: "rectangle.portrait.and.arrow.right")
        Text("Logout")
          .fontWeight(.semibold)
      }
      .font(.headline)
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background(Color.red)
      .cornerRadius(12)
    }
    .padding(.horizontal, 16)
    .padding(.bottom, 24)
    .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
  }
}

struct ProfileEmptyStateView: View {
  @Binding var showAuthView: Bool

  var body: some View {
    VStack(spacing: 32) {
      Spacer()

      VStack(spacing: 20) {
        VStack(spacing: 8) {
          Text("Welcome to OnlyFoods")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.primary)

          Text("Please login to view your profile")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
      }

      Button {
        showAuthView = true
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "person.fill")
          Text("Login")
            .fontWeight(.semibold)
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.vertical, 14)
        .frame(width: 200)
        .background(
          LinearGradient(
            colors: [Color.blue, Color.blue.opacity(0.8)],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .cornerRadius(12)
      }
      .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemGroupedBackground))
    .navigationTitle("Profile")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showAuthView) {
      AuthView()
    }
  }
}

struct ProfileListRow: View {
  let title: String
  let icon: String
  let iconColor: Color
  let count: Int

  var body: some View {
    HStack(spacing: 16) {
      // Icon
      ZStack {
        Circle()
          .fill(iconColor.opacity(0.15))
          .frame(width: 44, height: 44)
        Image(systemName: icon)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(iconColor)
      }

      // Title
      Text(title)
        .font(.headline)
        .foregroundStyle(.primary)

      Spacer()

      // Count badge
      if count > 0 {
        Text("\(count)")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(iconColor.opacity(0.1))
          .cornerRadius(8)
      }

      // Chevron indicator
      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.secondary.opacity(0.5))
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 16)
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
  ProfileTabView()
    .previewContainer()
}
