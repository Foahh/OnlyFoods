//
//  SearchView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftData
import SwiftUI

struct SearchView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var reviews: [ReviewModel]
  @Query private var users: [UserModel]
  @StateObject private var searchService = SearchService.shared
  @StateObject private var restaurantService = RestaurantService.shared

  var categories: [String] {
    Array(Set(restaurantService.restaurants.flatMap { $0.categories })).sorted()
  }

  var filteredRestaurants: [RestaurantModel] {
    var filtered = restaurantService.restaurants

    if !searchService.searchText.isEmpty {
      filtered = filtered.filter { restaurant in
        restaurant.name.localizedCaseInsensitiveContains(searchService.searchText)
          || restaurant.categories.contains {
            $0.localizedCaseInsensitiveContains(searchService.searchText)
          }
      }
    }

    if let category = searchService.selectedCategory {
      filtered = filtered.filter { $0.categories.contains(category) }
    }

    return filtered
  }

  var body: some View {
    VStack(spacing: 16) {
      // Category Filter
      VStack(alignment: .leading, spacing: 8) {
        Text("Filter by Category")
          .font(.headline)
          .padding(.horizontal)

        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            Button {
              searchService.setCategory(nil)
            } label: {
              Text("All")
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                  searchService.selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2)
                )
                .foregroundColor(searchService.selectedCategory == nil ? .white : .primary)
                .cornerRadius(20)
            }

            ForEach(categories, id: \.self) { category in
              Button {
                searchService.setCategory(category)
              } label: {
                Text(category)
                  .padding(.horizontal, 16)
                  .padding(.vertical, 8)
                  .background(
                    searchService.selectedCategory == category
                      ? Color.blue : Color.gray.opacity(0.2)
                  )
                  .foregroundColor(searchService.selectedCategory == category ? .white : .primary)
                  .cornerRadius(20)
              }
            }
          }
          .padding(.horizontal)
        }
      }

      // Search Results
      if filteredRestaurants.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "magnifyingglass")
            .font(.largeTitle)
            .foregroundColor(.secondary)
          Text("No restaurants found")
            .font(.headline)
            .foregroundColor(.secondary)
          if !searchService.searchText.isEmpty || searchService.selectedCategory != nil {
            Text("Try adjusting your search or filters")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List {
          ForEach(filteredRestaurants) { restaurant in
            NavigationLink {
              RestaurantDetailView(restaurant: restaurant)
            } label: {
              RestaurantCardView(restaurant: restaurant, reviews: reviews, users: users)
            }
          }
        }
        .listStyle(.plain)
      }
    }
  }
}

#Preview {
  SearchView()
    .previewContainer()
}
