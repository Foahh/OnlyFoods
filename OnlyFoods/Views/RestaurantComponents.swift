//
//  RestaurantComponents.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import SwiftUI

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
