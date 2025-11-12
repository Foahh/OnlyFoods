//
//  RestaurantDataService.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Combine
import Foundation

class RestaurantDataService: ObservableObject {
  @Published var restaurants: [RestaurantModel] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  static let shared = RestaurantDataService()

  private init() {
    loadRestaurants()
  }

  func loadRestaurants() {
    isLoading = true
    errorMessage = nil

    guard let url = Bundle.main.url(forResource: "restaurants", withExtension: "json") else {
      errorMessage = "Could not find restaurants.json file"
      isLoading = false
      return
    }

    do {
      let data = try Data(contentsOf: url)
      let decoder = JSONDecoder()
      restaurants = try decoder.decode([RestaurantModel].self, from: data)
      isLoading = false
    } catch {
      errorMessage = "Failed to load restaurants: \(error.localizedDescription)"
      isLoading = false
      print("Error loading restaurants: \(error)")
    }
  }

  func updateRestaurantRatings(with reviews: [ReviewModel]) {
    restaurants = restaurants.map { restaurant in
      let restaurantReviews = reviews.filter { $0.restaurantID == restaurant.id }
      return restaurant.updateRating(from: restaurantReviews)
    }
  }

  func getRestaurant(by id: UUID) -> RestaurantModel? {
    restaurants.first { $0.id == id }
  }
}
