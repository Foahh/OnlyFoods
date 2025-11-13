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

  var body: some View {
    NavigationStack {
      if let user = currentUser {
        ScrollView {
          VStack(spacing: 20) {
            // Profile Header
            VStack(spacing: 12) {
              if let avatar = user.avatar {
                AsyncImage(url: URL(string: avatar)) { image in
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                } placeholder: {
                  Circle()
                    .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
              } else {
                Circle()
                  .fill(Color.gray.opacity(0.3))
                  .frame(width: 100, height: 100)
                  .overlay {
                    Image(systemName: "person.fill")
                      .font(.system(size: 50))
                      .foregroundColor(.gray)
                  }
              }

              Text(user.username)
                .font(.title2)
                .fontWeight(.bold)
            }
            .padding()

            Divider()

            // Favorites Section
            VStack(alignment: .leading, spacing: 12) {
              Text("Favorite Restaurants")
                .font(.headline)
                .padding(.horizontal)

              if favoriteRestaurants.isEmpty {
                Text("No favorites yet")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
                  .padding()
                  .frame(maxWidth: .infinity)
                  .background(Color.gray.opacity(0.1))
                  .cornerRadius(8)
                  .padding(.horizontal)
              } else {
                ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 16) {
                    ForEach(favoriteRestaurants) { restaurant in
                      NavigationLink {
                        RestaurantDetailView(restaurant: restaurant)
                      } label: {
                        FavoriteRestaurantCard(restaurant: restaurant, reviews: reviews)
                      }
                    }
                  }
                  .padding(.horizontal)
                }
              }
            }

            Divider()

            // My Reviews Section
            VStack(alignment: .leading, spacing: 12) {
              Text("My Reviews")
                .font(.headline)
                .padding(.horizontal)

              if userReviews.isEmpty {
                Text("No reviews yet")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
                  .padding()
                  .frame(maxWidth: .infinity)
                  .background(Color.gray.opacity(0.1))
                  .cornerRadius(8)
                  .padding(.horizontal)
              } else {
                ForEach(userReviews) { review in
                  NavigationLink {
                    if let restaurant = restaurantService.getRestaurant(by: review.) {
                      RestaurantDetailView(restaurant: restaurant)
                    }
                  } label: {
                    UserReviewRowView(review: review, restaurants: restaurantService.restaurants)
                  }
                }
                .padding(.horizontal)
              }
            }

            Spacer()

            // Logout Button
            Button {
              userManager.logout()
            } label: {
              Text("Logout")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
            }
            .padding()
          }
        }
        .navigationTitle("Profile")
      } else {
        VStack(spacing: 20) {
          Image(systemName: "person.circle")
            .font(.system(size: 80))
            .foregroundColor(.gray)

          Text("Please login to view your profile")
            .font(.headline)
            .foregroundColor(.secondary)

          Button {
            showAuthView = true
          } label: {
            Text("Login")
              .font(.headline)
              .foregroundColor(.white)
              .padding()
              .frame(width: 200)
              .background(Color.blue)
              .cornerRadius(10)
          }
        }
        .navigationTitle("Profile")
        .sheet(isPresented: $showAuthView) {
          AuthView()
        }
      }
    }
    .onAppear {
      if userManager.currentUser == nil {
        showAuthView = true
      }
    }
  }
}

struct FavoriteRestaurantCard: View {
  let restaurant: RestaurantModel
  let reviews: [ReviewModel]

  var rating: RestaurantRating {
    restaurant.rating(from: reviews)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Restaurant Image - prefer doorImage, fallback to first image
      if let doorImage = restaurant.doorImage, let doorImageURL = URL(string: doorImage) {
        AsyncImage(url: doorImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Rectangle()
            .fill(Color.gray.opacity(0.3))
        }
        .frame(width: 150, height: 100)
        .cornerRadius(8)
      } else if let firstImage = restaurant.images.first, let firstImageURL = URL(string: firstImage) {
        AsyncImage(url: firstImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Rectangle()
            .fill(Color.gray.opacity(0.3))
        }
        .frame(width: 150, height: 100)
        .cornerRadius(8)
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.3))
          .frame(width: 150, height: 100)
          .cornerRadius(8)
          .overlay {
            Image(systemName: "photo")
              .foregroundColor(.gray)
          }
      }

      Text(restaurant.name)
        .font(.subheadline)
        .fontWeight(.semibold)
        .lineLimit(1)

      HStack(spacing: 4) {
        Image(systemName: "star.fill")
          .foregroundColor(.yellow)
          .font(.caption)
        Text(String(format: "%.1f", rating.averageRating))
          .font(.caption)
      }
    }
    .frame(width: 150)
  }
}

struct UserReviewRowView: View {
  let review: ReviewModel
  let restaurants: [RestaurantModel]

  var restaurant: RestaurantModel? {
    restaurants.first { $0.id == review.restaurantID }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let restaurant = restaurant {
        Text(restaurant.name)
          .font(.headline)
      }

      HStack(spacing: 4) {
        ForEach(1...5, id: \.self) { star in
          Image(systemName: star <= review.rating ? "star.fill" : "star")
            .foregroundColor(.yellow)
            .font(.caption)
        }
      }

      Text(review.comment)
        .font(.body)
        .lineLimit(3)

      Text(review.timestamp, style: .relative)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
    .background(Color.gray.opacity(0.05))
    .cornerRadius(12)
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: ReviewModel.self, UserModel.self, configurations: config)

  return ProfileTabView()
    .modelContainer(container)
}
