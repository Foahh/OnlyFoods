//
//  RestaurantComponents.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import Foundation
import SwiftUI

struct ConfirmButton: View {
  let action: () -> Void
  var icon: String = "arrow.up"
  var disabled: Bool = false

  var body: some View {
    if #available(iOS 26.0, *) {
      Button(role: .confirm) {
        action()
      } label: {
        Image(systemName: icon)
      }
      .disabled(disabled)
    } else {
      Button(action: action) {
        Image(systemName: icon)
      }
      .disabled(disabled)
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
        .fill(Color(.systemBackground).opacity(0.9))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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

struct RestaurantThumbnailView: View {
  let restaurant: RestaurantModel
  var size: CGFloat = 100
  var cornerRadius: CGFloat = 12

  private var imageURL: URL? {
    restaurant.primaryImageURL
  }

  var body: some View {
    Group {
      if let imageURL = imageURL {
        AsyncImage(url: imageURL) { phase in
          switch phase {
          case .empty:
            ThumbnailPlaceholder(showProgress: true)
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          case .failure:
            ThumbnailPlaceholder(showProgress: false)
          @unknown default:
            ThumbnailPlaceholder(showProgress: false)
          }
        }
      } else {
        ThumbnailPlaceholder(showProgress: false)
      }
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(Color(.separator), lineWidth: 0.5)
    )
  }
}

struct ThumbnailPlaceholder: View {
  let showProgress: Bool

  var body: some View {
    Rectangle()
      .fill(Color.gray.opacity(0.2))
      .overlay {
        if showProgress {
          ProgressView()
        } else {
          Image(systemName: "photo")
            .foregroundStyle(.secondary.opacity(0.5))
        }
      }
  }
}

struct RestaurantInfoView: View {
  let restaurant: RestaurantModel
  let rating: RestaurantRating

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(restaurant.name)
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)
        .lineLimit(2)

      RestaurantRatingView(rating: rating)

      if !restaurant.categories.isEmpty {
        Text(restaurant.categories.prefix(2).joined(separator: ", "))
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct RestaurantRatingView: View {
  let rating: RestaurantRating

  var body: some View {
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
  }
}

struct EmptyStateView: View {
  let icon: String
  let title: String
  let message: String

  var body: some View {
    VStack(spacing: 20) {
      Spacer()
        .frame(height: 100)

      Image(systemName: icon)
        .font(.system(size: 60))
        .foregroundStyle(.secondary.opacity(0.5))

      Text(title)
        .font(.title3)
        .fontWeight(.semibold)
        .foregroundStyle(.primary)

      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

extension RestaurantModel {
  /// Returns the primary image URL (doorImage if available, otherwise first image)
  var primaryImageURL: URL? {
    if let doorImage = doorImage, let url = URL(string: doorImage) {
      return url
    } else if let firstImage = images.first, let url = URL(string: firstImage) {
      return url
    }
    return nil
  }
}
