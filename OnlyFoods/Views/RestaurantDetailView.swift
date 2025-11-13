//
//  RestaurantDetailView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import MapKit
import SwiftData
import SwiftUI

struct RestaurantDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var userManager: UserManager
  @Query private var reviews: [ReviewModel]
  @Query private var users: [UserModel]
  @StateObject private var restaurantService = RestaurantService.shared
  @State private var showAddReview = false
  @State private var currentRestaurant: RestaurantModel

  private var currentUser: UserModel? {
    userManager.currentUser
  }

  init(restaurant: RestaurantModel) {
    _currentRestaurant = State(initialValue: restaurant)
  }

  var restaurantReviews: [ReviewModel] {
    reviews.filter { $0.restaurantID == currentRestaurant.id }
      .sorted { $0.timestamp > $1.timestamp }
  }

  var rating: RestaurantRating {
    currentRestaurant.rating(from: reviews)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // Images - show doorImage first if available, then other images
        if currentRestaurant.doorImage != nil || !currentRestaurant.images.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              // Show doorImage first if available
              if let doorImage = currentRestaurant.doorImage,
                let doorImageURL = URL(string: doorImage)
              {
                AsyncImage(url: doorImageURL) { image in
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                } placeholder: {
                  Rectangle()
                    .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 300, height: 200)
                .cornerRadius(12)
              }

              // Show other images
              ForEach(currentRestaurant.images, id: \.self) { imageURL in
                if let url = URL(string: imageURL) {
                  AsyncImage(url: url) { image in
                    image
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                  } placeholder: {
                    Rectangle()
                      .fill(Color.gray.opacity(0.3))
                  }
                  .frame(width: 300, height: 200)
                  .cornerRadius(12)
                }
              }
            }
            .padding(.horizontal)
          }
        }

        VStack(alignment: .leading, spacing: 12) {
          // Name and Rating
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text(currentRestaurant.name)
                .font(.largeTitle)
                .fontWeight(.bold)

              HStack(spacing: 4) {
                Image(systemName: "star.fill")
                  .foregroundColor(.yellow)
                Text(String(format: "%.1f", rating.averageRating))
                  .font(.title3)
                Text("(\(rating.reviewCount) reviews)")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }
            }

            Spacer()

            if let user = currentUser {
              Button {
                if user.isFavorite(restaurantID: currentRestaurant.id) {
                  user.removeFavorite(restaurantID: currentRestaurant.id)
                } else {
                  user.addFavorite(restaurantID: currentRestaurant.id)
                }
              } label: {
                Image(
                  systemName: user.isFavorite(restaurantID: currentRestaurant.id)
                    ? "heart.fill" : "heart"
                )
                .font(.title2)
                .foregroundColor(user.isFavorite(restaurantID: currentRestaurant.id) ? .red : .gray)
              }
            }
          }

          // Categories
          if !currentRestaurant.categories.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(currentRestaurant.categories, id: \.self) { category in
                  Text(category)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
              }
            }
          }

          Divider()

          // Description
          Text("About")
            .font(.headline)
          Text(currentRestaurant.description)
            .font(.body)
            .foregroundColor(.secondary)

          Divider()

          // Location Map
          Text("Location")
            .font(.headline)
          RestaurantMapView(
            latitude: currentRestaurant.latitude,
            longitude: currentRestaurant.longitude,
            restaurantName: currentRestaurant.name
          )
          .frame(height: 200)
          .cornerRadius(12)

          Divider()

          // Reviews Section
          HStack {
            Text("Reviews")
              .font(.headline)
            Spacer()
            if currentUser != nil {
              Button {
                showAddReview = true
              } label: {
                Label("Add Review", systemImage: "plus.circle.fill")
                  .font(.subheadline)
              }
            }
          }

          if restaurantReviews.isEmpty {
            Text("No reviews yet. Be the first to review!")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .padding()
              .frame(maxWidth: .infinity)
              .background(Color.gray.opacity(0.1))
              .cornerRadius(8)
          } else {
            ForEach(restaurantReviews) { review in
              ReviewRowView(review: review, users: users)
            }
          }
        }
        .padding()
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showAddReview) {
      if let user = currentUser {
        AddReviewView(restaurant: currentRestaurant, user: user)
      }
    }
  }
}

struct ReviewRowView: View {
  let review: ReviewModel
  let users: [UserModel]

  var reviewUser: UserModel? {
    users.first { $0.id == review.userID }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        if let user = reviewUser {
          if let avatar = user.avatar {
            AsyncImage(url: URL(string: avatar)) { image in
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            } placeholder: {
              Circle()
                .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
          } else {
            Circle()
              .fill(Color.gray.opacity(0.3))
              .frame(width: 40, height: 40)
              .overlay {
                Image(systemName: "person.fill")
                  .foregroundColor(.gray)
              }
          }
          Text(user.username)
            .font(.headline)
        } else {
          Text("Anonymous")
            .font(.headline)
        }

        Spacer()

        HStack(spacing: 4) {
          ForEach(1...5, id: \.self) { star in
            Image(systemName: star <= review.rating ? "star.fill" : "star")
              .foregroundColor(.yellow)
              .font(.caption)
          }
        }
      }

      Text(review.comment)
        .font(.body)

      if !review.images.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(review.images, id: \.self) { imageURL in
              AsyncImage(url: URL(string: imageURL)) { image in
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
              } placeholder: {
                Rectangle()
                  .fill(Color.gray.opacity(0.3))
              }
              .frame(width: 100, height: 100)
              .cornerRadius(8)
            }
          }
        }
      }

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
  let restaurantService = RestaurantService.shared
  restaurantService.loadRestaurants()
  return RestaurantDetailView(restaurant: restaurantService.restaurants[0])
    .modelContainer(container)
}
