//
//  SearchService.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import Combine
import CoreLocation
import Foundation

enum SortOption: String, CaseIterable {
  case score = "Rating"
  case mostFavorited = "Most Favorited"
  case mostVisited = "Most Visited"
  case priceLevel = "Price Level"
  case distance = "Distance"
}

enum SortDirection: String, CaseIterable {
  case ascending = "Ascending"
  case descending = "Descending"
}

enum DistanceFilter: Double, CaseIterable {
  case threeHundredMeters = 300
  case fiveHundredMeters = 500
  case oneKilometer = 1000
  case onePointFiveKilometers = 1500
  case twoKilometers = 2000

  var displayName: String {
    switch self {
    case .threeHundredMeters:
      return "300 m"
    case .fiveHundredMeters:
      return "500 m"
    case .oneKilometer:
      return "1 km"
    case .onePointFiveKilometers:
      return "1.5 km"
    case .twoKilometers:
      return "2 km"
    }
  }
}

class SearchService: ObservableObject {
  @Published var searchText: String = ""
  @Published var selectedCategories: Set<String> = []
  @Published var selectedDistance: DistanceFilter?
  @Published var selectedServices: Set<String> = []
  @Published var isOpenNow: Bool = false
  @Published var selectedPriceLevels: Set<Int> = []
  @Published var sortOption: SortOption = .score
  @Published var sortDirection: SortDirection = .descending
  @Published var userLocation: CLLocation?

  init() {}

  func clearSearch() {
    searchText = ""
    clearFilters()
  }

  func clearFilters() {
    selectedCategories.removeAll()
    selectedDistance = nil
    selectedServices.removeAll()
    isOpenNow = false
    selectedPriceLevels.removeAll()
    sortOption = .score
    sortDirection = .descending
  }

  func toggleCategory(_ category: String) {
    if selectedCategories.contains(category) {
      selectedCategories.remove(category)
    } else {
      selectedCategories.insert(category)
    }
  }

  func toggleService(_ service: String) {
    if selectedServices.contains(service) {
      selectedServices.remove(service)
    } else {
      selectedServices.insert(service)
    }
  }

  func togglePriceLevel(_ priceLevel: Int) {
    if selectedPriceLevels.contains(priceLevel) {
      selectedPriceLevels.remove(priceLevel)
    } else {
      selectedPriceLevels.insert(priceLevel)
    }
  }

  var hasActiveSearch: Bool {
    !searchText.isEmpty || hasActiveFilters
  }

  var hasActiveFilters: Bool {
    !selectedCategories.isEmpty
      || selectedDistance != nil
      || !selectedServices.isEmpty
      || isOpenNow
      || !selectedPriceLevels.isEmpty
  }
}

struct RestaurantFilter {
  static func filter(
    restaurants: [RestaurantModel],
    searchService: SearchService
  ) -> [RestaurantModel] {
    var filtered = restaurants

    // Apply text search
    if !searchService.searchText.isEmpty {
      filtered = filtered.filter { restaurant in
        restaurant.name.localizedCaseInsensitiveContains(searchService.searchText)
          || restaurant.categories.contains {
            $0.localizedCaseInsensitiveContains(searchService.searchText)
          }
      }
    }

    // Apply category filter (multi-select)
    if !searchService.selectedCategories.isEmpty {
      filtered = filtered.filter { restaurant in
        !Set(restaurant.categories).isDisjoint(with: searchService.selectedCategories)
      }
    }

    // Apply service filter
    if !searchService.selectedServices.isEmpty {
      filtered = filtered.filter { restaurant in
        guard let services = restaurant.services else { return false }
        return !Set(services).isDisjoint(with: searchService.selectedServices)
      }
    }

    // Apply open now filter
    if searchService.isOpenNow {
      filtered = filtered.filter { $0.isCurrentlyOpen() }
    }

    // Apply price level filter
    if !searchService.selectedPriceLevels.isEmpty {
      filtered = filtered.filter { restaurant in
        guard let priceLevel = restaurant.priceLevel else { return false }
        return searchService.selectedPriceLevels.contains(priceLevel)
      }
    }

    // Apply distance filter
    if let distance = searchService.selectedDistance,
      let userLocation = searchService.userLocation
    {
      filtered = filtered.filter { restaurant in
        let distanceInMeters = DistanceCalculator.distance(
          from: userLocation,
          to: restaurant.coordinate
        )
        return distanceInMeters <= distance.rawValue
      }
    }

    return filtered
  }
}

struct RestaurantSorter {
  static func sort(
    restaurants: [RestaurantModel],
    sortOption: SortOption,
    sortDirection: SortDirection,
    searchService: SearchService,
    restaurantService: RestaurantService,
    reviews: [ReviewModel],
    users: [UserModel]
  ) -> [RestaurantModel] {
    let isAscending = sortDirection == .ascending

    switch sortOption {
    case .score:
      return restaurants.sorted { restaurant1, restaurant2 in
        let rating1 = restaurantService.getRatingDetails(
          for: restaurant1.id,
          from: reviews
        )
        let rating2 = restaurantService.getRatingDetails(
          for: restaurant2.id,
          from: reviews
        )
        return isAscending
          ? rating1.averageRating < rating2.averageRating
          : rating1.averageRating > rating2.averageRating
      }
    case .mostFavorited:
      return restaurants.sorted { restaurant1, restaurant2 in
        let count1 = restaurantService.getFavoriteCount(
          for: restaurant1.id,
          from: users
        )
        let count2 = restaurantService.getFavoriteCount(
          for: restaurant2.id,
          from: users
        )
        return isAscending ? count1 < count2 : count1 > count2
      }
    case .mostVisited:
      return restaurants.sorted { restaurant1, restaurant2 in
        let count1 = restaurantService.getVisitedCount(
          for: restaurant1.id,
          from: users
        )
        let count2 = restaurantService.getVisitedCount(
          for: restaurant2.id,
          from: users
        )
        return isAscending ? count1 < count2 : count1 > count2
      }
    case .priceLevel:
      return restaurants.sorted { restaurant1, restaurant2 in
        let price1 = restaurant1.priceLevel ?? Int.max
        let price2 = restaurant2.priceLevel ?? Int.max
        return isAscending ? price1 < price2 : price1 > price2
      }
    case .distance:
      guard let userLocation = searchService.userLocation else {
        return restaurants
      }
      return restaurants.sorted { restaurant1, restaurant2 in
        let distance1 = DistanceCalculator.distance(
          from: userLocation,
          to: restaurant1.coordinate
        )
        let distance2 = DistanceCalculator.distance(
          from: userLocation,
          to: restaurant2.coordinate
        )
        return isAscending ? distance1 > distance2 : distance1 < distance2
      }
    }
  }
}
