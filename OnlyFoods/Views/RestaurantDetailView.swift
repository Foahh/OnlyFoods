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
  @Query private var reviews: [ReviewModel]
  @Query private var users: [UserModel]
  @StateObject private var restaurantService = RestaurantDataService.shared
  @State private var currentUser: UserModel?
  @State private var showAddReview = false
  @State private var currentRestaurant: RestaurantModel

  init(restaurant: RestaurantModel) {
    _currentRestaurant = State(initialValue: restaurant)
  }

  var restaurantReviews: [ReviewModel] {
    reviews.filter { $0.restaurantID == currentRestaurant.id }
      .sorted { $0.timestamp > $1.timestamp }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // Images
        if !currentRestaurant.images.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              ForEach(currentRestaurant.images, id: \.self) { imageURL in
                AsyncImage(url: URL(string: imageURL)) { image in
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
                Text(String(format: "%.1f", currentRestaurant.averageRating))
                  .font(.title3)
                Text("(\(currentRestaurant.reviewCount) reviews)")
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

          // Category and Tags
          Text(currentRestaurant.cuisineCategory)
            .font(.headline)
            .foregroundColor(.blue)

          if !currentRestaurant.tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(currentRestaurant.tags, id: \.self) { tag in
                  Text(tag)
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
    .onAppear {
      // Get current user (in a real app, this would come from authentication)
      currentUser = users.first
      updateRestaurantRating()
    }
    .onChange(of: reviews) { _, _ in
      updateRestaurantRating()
    }
  }

  private func updateRestaurantRating() {
    let restaurantReviews = reviews.filter { $0.restaurantID == currentRestaurant.id }
    currentRestaurant = currentRestaurant.updateRating(from: restaurantReviews)
    restaurantService.updateRestaurantRatings(with: reviews)
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

  return NavigationStack {
    RestaurantDetailView(
      restaurant: RestaurantModel(
        name: "Sample Restaurant",
        description: "A great place to eat",
        latitude: 22.3193,
        longitude: 114.1694,
        cuisineCategory: "Italian"
      ))
  }
  .modelContainer(container)
}
