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
  @StateObject private var timeService = TimeService.shared
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

  var isOpenNow: Bool {
    currentRestaurant.isOpen(at: timeService.currentTime)
  }

  private var priceText: String? {
    guard let level = currentRestaurant.priceLevel, level > 0 else { return nil }
    return String(repeating: "$", count: level)
  }

  private var favoriteCount: Int {
    RestaurantService.shared.getFavoriteCount(for: currentRestaurant.id, from: users)
  }

  private var visitedCount: Int {
    RestaurantService.shared.getVisitedCount(for: currentRestaurant.id, from: users)
  }

  var body: some View {
    ScrollView {
      VStack {
        // Content Section
        VStack(alignment: .leading, spacing: 20) {
          // Header: Name, Rating, and Favorite Button
          VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
              Text(currentRestaurant.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

              RatingView(rating: rating)
            }

            if let user = currentUser {
              HStack(spacing: 12) {
                Button {
                  if user.isVisited(restaurantID: currentRestaurant.id) {
                    user.removeVisited(restaurantID: currentRestaurant.id)
                  } else {
                    user.addVisited(restaurantID: currentRestaurant.id)
                  }
                } label: {
                  HStack {
                    Image(
                      systemName: user.isVisited(restaurantID: currentRestaurant.id)
                        ? "checkmark.circle.fill" : "checkmark.circle"
                    )
                    .font(.title3)
                    Text("Visited")
                      .font(.headline)
                  }
                  .frame(maxWidth: .infinity)
                  .frame(height: 50)
                  .foregroundStyle(
                    user.isVisited(restaurantID: currentRestaurant.id) ? .white : .blue
                  )
                  .background(
                    user.isVisited(restaurantID: currentRestaurant.id)
                      ? Color.blue : Color.blue.opacity(0.1)
                  )
                  .clipShape(Capsule())
                }

                Button {
                  if user.isFavorite(restaurantID: currentRestaurant.id) {
                    user.removeFavorite(restaurantID: currentRestaurant.id)
                  } else {
                    user.addFavorite(restaurantID: currentRestaurant.id)
                  }
                } label: {
                  HStack {
                    Image(
                      systemName: user.isFavorite(restaurantID: currentRestaurant.id)
                        ? "heart.fill" : "heart"
                    )
                    .font(.title3)
                    Text("Favorite")
                      .font(.headline)
                  }
                  .frame(maxWidth: .infinity)
                  .frame(height: 50)
                  .foregroundStyle(
                    user.isFavorite(restaurantID: currentRestaurant.id) ? .white : .red
                  )
                  .background(
                    user.isFavorite(restaurantID: currentRestaurant.id)
                      ? Color.red : Color.red.opacity(0.1)
                  )
                  .clipShape(Capsule())
                }
              }
            }

            // Favorite/Visited Counts
            HStack(spacing: 20) {
              HStack(spacing: 6) {
                Image(systemName: favoriteCount > 0 ? "heart.fill" : "heart")
                  .font(.subheadline)
                  .foregroundStyle(favoriteCount > 0 ? .red : .secondary.opacity(0.5))
                if favoriteCount > 0 {
                  Text("\(favoriteCount) favorites")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else {
                  Text("No favorites yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary.opacity(0.6))
                    .italic()
                }
              }

              HStack(spacing: 6) {
                Image(systemName: visitedCount > 0 ? "checkmark.circle.fill" : "checkmark.circle")
                  .font(.subheadline)
                  .foregroundStyle(visitedCount > 0 ? .blue : .secondary.opacity(0.5))
                if visitedCount > 0 {
                  Text("\(visitedCount) visits")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                } else {
                  Text("No visits yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary.opacity(0.6))
                    .italic()
                }
              }
            }
          }

          // Categories and Price
          if !currentRestaurant.categories.isEmpty || priceText != nil {
            CategoryChipsView(
              categories: currentRestaurant.categories,
              priceText: priceText
            )
          }

          Divider()
            .padding(.top, 8)

          // Additional Images Gallery
          if currentRestaurant.images.count > 1
            || (currentRestaurant.doorImage != nil && !currentRestaurant.images.isEmpty)
          {
            VStack(alignment: .leading, spacing: 12) {
              Text("Photos")
                .font(.headline)
                .foregroundStyle(.primary)

              ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                  // Show doorImage if available and not already shown
                  if let doorImage = currentRestaurant.doorImage,
                    let doorImageURL = URL(string: doorImage)
                  {
                    RestaurantImageItem(url: doorImageURL)
                  }

                  // Show other images
                  ForEach(currentRestaurant.images, id: \.self) { imageURL in
                    if let url = URL(string: imageURL) {
                      RestaurantImageItem(url: url)
                    }
                  }
                }
                .padding(.horizontal, 4)
              }
            }
          }

          Divider()
            .padding(.top, 8)

          // Location Map
          VStack(alignment: .leading, spacing: 12) {
            Text("Location")
              .font(.headline)
              .foregroundStyle(.primary)

            RestaurantMapView(
              latitude: currentRestaurant.latitude,
              longitude: currentRestaurant.longitude,
              restaurantName: currentRestaurant.name
            )
            .frame(height: 200)
            .cornerRadius(12)
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 0.5)
            )
          }

          Divider()
            .padding(.top, 8)

          // Reviews Section
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Text("Reviews")
                .font(.headline)
                .foregroundStyle(.primary)
              Spacer()
              if currentUser != nil {
                Button {
                  showAddReview = true
                } label: {
                  Label("Add Review", systemImage: "plus.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
              }
            }

            if restaurantReviews.isEmpty {
              VStack(spacing: 12) {
                Image(systemName: "star.bubble")
                  .font(.system(size: 48))
                  .foregroundStyle(.secondary.opacity(0.5))
                Text("No reviews yet")
                  .font(.headline)
                  .foregroundStyle(.primary)
                if currentUser != nil {
                  Text("Be the first to review this restaurant!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 32)
              .background(Color(.systemGray6))
              .cornerRadius(12)
            } else {
              LazyVStack(spacing: 16) {
                ForEach(restaurantReviews) { review in
                  ReviewRowView(review: review, users: users)
                }
              }
            }
          }
        }
        .padding(20)
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
    VStack(alignment: .leading, spacing: 12) {
      // User Info and Rating
      HStack(alignment: .top, spacing: 12) {
        // Avatar
        if let user = reviewUser {
          if let avatar = user.avatar, let avatarURL = URL(string: avatar) {
            AsyncImage(url: avatarURL) { phase in
              switch phase {
              case .empty:
                AvatarPlaceholder()
              case .success(let image):
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
              case .failure:
                AvatarPlaceholder()
              @unknown default:
                AvatarPlaceholder()
              }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
          } else {
            AvatarPlaceholder()
              .frame(width: 44, height: 44)
          }
        } else {
          AvatarPlaceholder()
            .frame(width: 44, height: 44)
        }

        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text(reviewUser?.username ?? "Anonymous")
              .font(.headline)
              .foregroundStyle(.primary)

            Spacer()

            // Star Rating
            HStack(spacing: 2) {
              ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= review.rating ? "star.fill" : "star")
                  .foregroundStyle(star <= review.rating ? .yellow : .yellow.opacity(0.3))
                  .font(.caption)
              }
            }
          }

          Text(review.timestamp, style: .relative)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      // Review Comment
      if !review.comment.isEmpty {
        Text(review.comment)
          .font(.body)
          .foregroundStyle(.primary)
          .fixedSize(horizontal: false, vertical: true)
      }

      // Review Images
      if !review.images.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(review.images, id: \.self) { imageURL in
              if let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                  switch phase {
                  case .empty:
                    ReviewImagePlaceholder()
                  case .success(let image):
                    image
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                  case .failure:
                    ReviewImagePlaceholder()
                  @unknown default:
                    ReviewImagePlaceholder()
                  }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
              }
            }
          }
        }
      }
    }
    .padding(16)
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(.separator), lineWidth: 0.5)
    )
    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}

// MARK: - Supporting Views

struct RestaurantDetailImageView: View {
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

struct RestaurantImageItem: View {
  let url: URL

  var body: some View {
    AsyncImage(url: url) { phase in
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
    .frame(width: 200, height: 150)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

struct AvatarPlaceholder: View {
  var body: some View {
    Circle()
      .fill(Color(.systemGray5))
      .overlay {
        Image(systemName: "person.fill")
          .font(.system(size: 20))
          .foregroundStyle(.secondary.opacity(0.6))
      }
  }
}

struct ReviewImagePlaceholder: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color(.systemGray5))
      .overlay {
        Image(systemName: "photo")
          .font(.system(size: 24))
          .foregroundStyle(.secondary.opacity(0.5))
      }
  }
}

#Preview {
  RestaurantDetailView(
    restaurant: RestaurantModel(
      id: "test-restaurant-id",
      name: "Sample Restaurant",
      latitude: 22.3193,
      longitude: 114.1694,
      categories: ["Italian"]
    )
  )
  .previewContainer(withMockData: true)
}
