//
//  ExploreTabView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import MapKit
import SwiftData
import SwiftUI

struct ExploreTabView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var reviews: [ReviewModel]
  @StateObject private var restaurantService = RestaurantDataService.shared
  @State private var selectedRestaurant: RestaurantModel?
  @State private var cameraPosition: MapCameraPosition = .region(
    MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),  // Default to Hong Kong
      span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
  )
  @State private var showSearchView = false
  @State private var searchText = ""
  @State private var selectedCategory: String?

  var filteredRestaurants: [RestaurantModel] {
    var filtered = restaurantService.restaurants

    if !searchText.isEmpty {
      filtered = filtered.filter { restaurant in
        restaurant.name.localizedCaseInsensitiveContains(searchText)
          || restaurant.cuisineCategory.localizedCaseInsensitiveContains(searchText)
          || restaurant.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
      }
    }

    if let category = selectedCategory {
      filtered = filtered.filter { $0.cuisineCategory == category }
    }

    return filtered
  }

  func rating(for restaurant: RestaurantModel) -> RestaurantRating {
    restaurant.rating(from: reviews)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        // Map View
        Map(position: $cameraPosition) {
          ForEach(filteredRestaurants) { restaurant in
            Annotation(
              restaurant.name,
              coordinate: CLLocationCoordinate2D(
                latitude: restaurant.latitude,
                longitude: restaurant.longitude
              )
            ) {
              Button {
                selectedRestaurant = restaurant
              } label: {
                VStack(spacing: 4) {
                  Image(systemName: "mappin.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                  Text(String(format: "%.1f", rating(for: restaurant).averageRating))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(4)
                    .background(Color.white)
                    .cornerRadius(4)
                    .shadow(radius: 2)
                }
              }
            }
          }
        }
        .frame(height: 300)

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
      }
      .navigationTitle("Explore")
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
      // Restaurant Image
      if let firstImage = restaurant.images.first {
        AsyncImage(url: URL(string: firstImage)) { image in
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

        Text(restaurant.cuisineCategory)
          .font(.subheadline)
          .foregroundColor(.secondary)

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

        if !restaurant.tags.isEmpty {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
              ForEach(restaurant.tags.prefix(3), id: \.self) { tag in
                Text(tag)
                  .font(.caption2)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(Color.blue.opacity(0.1))
                  .foregroundColor(.blue)
                  .cornerRadius(8)
              }
            }
          }
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
