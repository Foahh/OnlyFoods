//
//  UserModel.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Foundation
import SwiftData

@Model
final class UserModel {
  @Attribute(.unique) var id: UUID
  var username: String
  var avatar: String?  // URL or asset name
  var favoriteRestaurantIDs: [String]
  var visitedRestaurantIDs: [String]
  @Relationship(deleteRule: .cascade) var reviews: [ReviewModel]?

  init(
    id: UUID = UUID(),
    username: String,
    avatar: String? = nil,
    favoriteRestaurantIDs: [String] = [],
    visitedRestaurantIDs: [String] = []
  ) {
    self.id = id
    self.username = username
    self.avatar = avatar
    self.favoriteRestaurantIDs = favoriteRestaurantIDs
    self.visitedRestaurantIDs = visitedRestaurantIDs
    self.reviews = []
  }

  func addFavorite(restaurantID: String) {
    if !favoriteRestaurantIDs.contains(restaurantID) {
      favoriteRestaurantIDs.append(restaurantID)
    }
  }

  func removeFavorite(restaurantID: String) {
    favoriteRestaurantIDs.removeAll { $0 == restaurantID }
  }

  func isFavorite(restaurantID: String) -> Bool {
    favoriteRestaurantIDs.contains(restaurantID)
  }

  func addVisited(restaurantID: String) {
    if !visitedRestaurantIDs.contains(restaurantID) {
      visitedRestaurantIDs.append(restaurantID)
    }
  }

  func removeVisited(restaurantID: String) {
    visitedRestaurantIDs.removeAll { $0 == restaurantID }
  }

  func isVisited(restaurantID: String) -> Bool {
    visitedRestaurantIDs.contains(restaurantID)
  }
}
