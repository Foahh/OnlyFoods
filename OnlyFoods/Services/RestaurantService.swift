//
//  RestaurantService.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Combine
import Foundation

class RestaurantService: ObservableObject {
  @Published var restaurants: [RestaurantModel] = []
  @Published var isLoading = false

  static let shared = RestaurantService()

  private let jsonLoader: JSONLoader = JSONLoader()
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
    var loadErrors: [String] = []

    for filename in dataSourceFiles {
      let result = await jsonLoader.loadRestaurants(from: filename)

      switch result {
      case .success(let restaurants):
        allRestaurants.append(contentsOf: restaurants)
        print("Loaded \(restaurants.count) restaurants from \(filename).json")
      case .failure(let error):
        let errorMessage = "Failed to load \(filename).json: \(error.localizedDescription)"
        loadErrors.append(errorMessage)
        print("Warning: \(errorMessage)")
      }
    }

    let (uniqueRestaurants, duplicateCount) = deduplicateRestaurants(allRestaurants)
    restaurants = uniqueRestaurants

    if duplicateCount > 0 {
      print("Merged \(duplicateCount) duplicate restaurant(s)")
    }

    if !loadErrors.isEmpty && restaurants.isEmpty {
      for error in loadErrors {
        print("Error: \(error)")
      }
    }

    isLoading = false
    print("Total unique restaurants loaded: \(restaurants.count)")
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
      description: second.description.isEmpty ? first.description : second.description,
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
}

private struct JSONLoader {
  private let decoder = JSONDecoder()
  private let subdirectory = "Data/Restaurants"

  func loadRestaurants(from filename: String) async -> Result<[RestaurantModel], Error> {
    guard let url = findJSONFile(named: filename) else {
      return .failure(JSONLoadError.fileNotFound(filename))
    }

    do {
      let data = try await loadData(from: url)
      let restaurants = try decoder.decode([RestaurantModel].self, from: data)
      return .success(restaurants)
    } catch {
      return .failure(error)
    }
  }

  private func findJSONFile(named filename: String) -> URL? {
    Bundle.main.url(
      forResource: filename,
      withExtension: "json",
      subdirectory: subdirectory
    )
  }

  private func loadData(from url: URL) async throws -> Data {
    try Data(contentsOf: url)
  }
}

private enum JSONLoadError: Error {
  case fileNotFound(String)

  var errorDescription: String? {
    switch self {
    case .fileNotFound(let filename):
      return "Could not find \(filename).json file"
    }
  }
}
