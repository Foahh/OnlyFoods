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
  var favoriteRestaurantIDs: [UUID]
  @Relationship(deleteRule: .cascade) var reviews: [ReviewModel]?

  init(
    id: UUID = UUID(),
    username: String,
    avatar: String? = nil,
    favoriteRestaurantIDs: [UUID] = []
  ) {
    self.id = id
    self.username = username
    self.avatar = avatar
    self.favoriteRestaurantIDs = favoriteRestaurantIDs
    self.reviews = []
  }

  func addFavorite(restaurantID: UUID) {
    if !favoriteRestaurantIDs.contains(restaurantID) {
      favoriteRestaurantIDs.append(restaurantID)
    }
  }

  func removeFavorite(restaurantID: UUID) {
    favoriteRestaurantIDs.removeAll { $0 == restaurantID }
  }

  func isFavorite(restaurantID: UUID) -> Bool {
    favoriteRestaurantIDs.contains(restaurantID)
  }
}
