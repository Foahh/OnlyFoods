//
//  RestaurantService.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Combine
import Foundation
import SwiftData

class RestaurantService: ObservableObject {
  @Published var restaurants: [RestaurantModel] = []
  @Published var isLoading = false

  static let shared = RestaurantService()

  private let dataSourceFiles = ["mock", "openrice"]

  init() {
    loadRestaurants()
  }

  func loadRestaurants() {
    isLoading = true
    Task {
      await performLoadRestaurants()
    }
  }

  @MainActor
  private func performLoadRestaurants() async {
    var allRestaurants: [RestaurantModel] = []

    for filename in dataSourceFiles {
      let result = await loadRestaurants(from: filename)
      if let restaurants = result {
        allRestaurants.append(contentsOf: restaurants)
      }
    }

    let (uniqueRestaurants, duplicateCount) = deduplicateRestaurants(allRestaurants)
    restaurants = uniqueRestaurants

    if duplicateCount > 0 {
      print("Merged \(duplicateCount) duplicate restaurant(s)")
    }

    isLoading = false
    print("Total restaurants loaded: \(restaurants.count)")
  }

  private func deduplicateRestaurants(_ restaurants: [RestaurantModel]) -> ([RestaurantModel], Int)
  {
    var restaurantDict: [String: RestaurantModel] = [:]
    var duplicateCount = 0

    for restaurant in restaurants {
      if let existing = restaurantDict[restaurant.id] {
        duplicateCount += 1
        restaurantDict[restaurant.id] = mergeRestaurants(existing, restaurant)
        print("Warning: Duplicate restaurant ID found: \(restaurant.id). Merging data.")
      } else {
        restaurantDict[restaurant.id] = restaurant
      }
    }

    return (Array(restaurantDict.values), duplicateCount)
  }

  /// Merges two restaurant models, preferring non-nil values from the second restaurant
  private func mergeRestaurants(_ first: RestaurantModel, _ second: RestaurantModel)
    -> RestaurantModel
  {
    return RestaurantModel(
      id: first.id,
      name: second.name.isEmpty ? first.name : second.name,
      latitude: second.latitude != 0 ? second.latitude : first.latitude,
      longitude: second.longitude != 0 ? second.longitude : first.longitude,
      images: second.images.isEmpty ? first.images : second.images,
      doorImage: second.doorImage ?? first.doorImage,
      categories: second.categories.isEmpty ? first.categories : second.categories,
      services: second.services ?? first.services,
      paymentMethods: second.paymentMethods ?? first.paymentMethods,
      contactPhone: second.contactPhone ?? first.contactPhone,
      addressString: second.addressString ?? first.addressString,
      businessHours: second.businessHours ?? first.businessHours,
      priceLevel: second.priceLevel ?? first.priceLevel
    )
  }

  func getRatingDetails(for restaurantID: String, from reviews: [ReviewModel]) -> RestaurantRating {
    let restaurantReviews = reviews.filter { $0.restaurantID == restaurantID }
    return RestaurantRating.compute(from: restaurantReviews)
  }

  func getRestaurant(by id: String) -> RestaurantModel? {
    restaurants.first { $0.id == id }
  }

  /// Get the count of users who have favorited a restaurant
  func getFavoriteCount(for restaurantID: String, from users: [UserModel]) -> Int {
    users.filter { $0.isFavorite(restaurantID: restaurantID) }.count
  }

  /// Get the count of users who have visited a restaurant
  func getVisitedCount(for restaurantID: String, from users: [UserModel]) -> Int {
    users.filter { $0.isVisited(restaurantID: restaurantID) }.count
  }

  func loadRestaurants(from filename: String) async -> [RestaurantModel]? {
    guard
      let url = Bundle.main.url(
        forResource: filename,
        withExtension: "json",
      )
    else {
      return nil
    }

    do {
      let decoder = JSONDecoder()
      let data = try Data(contentsOf: url)
      let restaurants = try decoder.decode([RestaurantModel].self, from: data)
      return restaurants
    } catch {
      print("Error loading restaurants from \(filename).json: \(error.localizedDescription)")
      return nil
    }
  }
}
