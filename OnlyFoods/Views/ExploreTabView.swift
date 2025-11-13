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
  @StateObject private var restaurantService = RestaurantService.shared
  @State private var showSearchView = false
  @State private var searchText = ""
  @State private var selectedCategory: String?

  var filteredRestaurants: [RestaurantModel] {
    var filtered = restaurantService.restaurants

    if !searchText.isEmpty {
      filtered = filtered.filter { restaurant in
        restaurant.name.localizedCaseInsensitiveContains(searchText)
          || restaurant.categories.contains { $0.localizedCaseInsensitiveContains(searchText) }
      }
    }

    if let category = selectedCategory {
      filtered = filtered.filter { $0.categories.contains(category) }
    }

    return filtered
  }

  var body: some View {
    NavigationStack {
      // Restaurant List
      List {
        ForEach(filteredRestaurants) { restaurant in
          NavigationLink {
            RestaurantDetailView(restaurant: restaurant)
          } label: {
            RestaurantRowView(restaurant: restaurant, reviews: reviews)
          }
        }
      }
      .listStyle(.plain)
      .navigationTitle("Explore")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            showSearchView = true
          } label: {
            Image(systemName: "magnifyingglass")
          }
        }
      }
      .sheet(isPresented: $showSearchView) {
        SearchView(
          searchText: $searchText,
          selectedCategory: $selectedCategory,
          restaurants: restaurantService.restaurants
        )
      }
    }
  }
}

struct RestaurantRowView: View {
  let restaurant: RestaurantModel
  let reviews: [ReviewModel]

  var rating: RestaurantRating {
    restaurant.rating(from: reviews)
  }

  var body: some View {
    HStack(spacing: 12) {
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
        .frame(width: 80, height: 80)
        .cornerRadius(8)
      } else if let firstImage = restaurant.images.first,
        let firstImageURL = URL(string: firstImage)
      {
        AsyncImage(url: firstImageURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Rectangle()
            .fill(Color.gray.opacity(0.3))
        }
        .frame(width: 80, height: 80)
        .cornerRadius(8)
      } else {
        Rectangle()
          .fill(Color.gray.opacity(0.3))
          .frame(width: 80, height: 80)
          .cornerRadius(8)
          .overlay {
            Image(systemName: "photo")
              .foregroundColor(.gray)
          }
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(restaurant.name)
          .font(.headline)

        if !restaurant.categories.isEmpty {
          Text(restaurant.categories.prefix(2).joined(separator: " | "))
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        HStack(spacing: 4) {
          Image(systemName: "star.fill")
            .foregroundColor(.yellow)
            .font(.caption)
          Text(String(format: "%.1f", rating.averageRating))
            .font(.caption)
          Text("(\(rating.reviewCount))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      Spacer()
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: ReviewModel.self, UserModel.self, configurations: config)

  return ExploreTabView()
    .modelContainer(container)
}
