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
    ScrollView {
      if visitedRestaurants.isEmpty {
        VStack(spacing: 20) {
          Spacer()
            .frame(height: 100)

          Image(systemName: "checkmark.circle")
            .font(.system(size: 60))
            .foregroundStyle(.secondary.opacity(0.5))

          Text("No visited restaurants yet")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)

          Text("Mark restaurants as visited to keep track of your dining experiences")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)

          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        LazyVStack(spacing: 16) {
          ForEach(visitedRestaurants) { restaurant in
            NavigationLink {
              RestaurantDetailView(restaurant: restaurant)
            } label: {
              VisitedRestaurantRow(restaurant: restaurant, reviews: reviews)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
      }
    }
    .navigationTitle("Visited Restaurants")
    .navigationBarTitleDisplayMode(.large)
    .background(Color(.systemGroupedBackground))
  }
}

struct VisitedRestaurantRow: View {
  let restaurant: RestaurantModel
  let reviews: [ReviewModel]

  var rating: RestaurantRating {
    restaurant.rating(from: reviews)
  }

  var body: some View {
    HStack(spacing: 16) {
      // Restaurant Image
      Group {
        if let doorImage = restaurant.doorImage, let doorImageURL = URL(string: doorImage) {
          AsyncImage(url: doorImageURL) { phase in
            switch phase {
            case .empty:
              Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                  ProgressView()
                }
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            case .failure:
              Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                  Image(systemName: "photo")
                    .foregroundStyle(.secondary.opacity(0.5))
                }
            @unknown default:
              Rectangle()
                .fill(Color.gray.opacity(0.2))
            }
          }
        } else if let firstImage = restaurant.images.first,
          let firstImageURL = URL(string: firstImage)
        {
          AsyncImage(url: firstImageURL) { phase in
            switch phase {
            case .empty:
              Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                  ProgressView()
                }
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fill)
            case .failure:
              Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                  Image(systemName: "photo")
                    .foregroundStyle(.secondary.opacity(0.5))
                }
            @unknown default:
              Rectangle()
                .fill(Color.gray.opacity(0.2))
            }
          }
        } else {
          Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
              Image(systemName: "photo")
                .foregroundStyle(.secondary.opacity(0.5))
            }
        }
      }
      .frame(width: 100, height: 100)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color(.separator), lineWidth: 0.5)
      )

      // Restaurant Info
      VStack(alignment: .leading, spacing: 8) {
        Text(restaurant.name)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundStyle(.primary)
          .lineLimit(2)

        if rating.reviewCount > 0 {
          HStack(spacing: 4) {
            Image(systemName: "star.fill")
              .foregroundStyle(.yellow)
              .font(.caption)
            Text(String(format: "%.1f", rating.averageRating))
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundStyle(.secondary)
            Text("(\(rating.reviewCount))")
              .font(.caption)
              .foregroundStyle(.secondary.opacity(0.7))
          }
        } else {
          Text("No ratings yet")
            .font(.caption)
            .foregroundStyle(.secondary.opacity(0.7))
        }

        if !restaurant.categories.isEmpty {
          Text(restaurant.categories.prefix(2).joined(separator: ", "))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // Chevron
      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundStyle(.secondary.opacity(0.5))
    }
    .padding(16)
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
  NavigationStack {
    VisitedRestaurantsView()
      .previewContainer()
  }
}
