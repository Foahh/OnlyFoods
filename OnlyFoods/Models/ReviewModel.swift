//
//  ReviewModel.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Foundation
import SwiftData

@Model
final class ReviewModel {
  @Attribute(.unique) var id: UUID
  var restaurantID: String
  @Relationship(inverse: \UserModel.reviews) var user: UserModel?
  var rating: Int  // 1-5 stars
  var comment: String
  var images: [String]  // URLs or asset names
  var timestamp: Date

  init(
    id: UUID = UUID(),
    restaurantID: String,
    user: UserModel?,
    rating: Int,
    comment: String,
    images: [String] = [],
    timestamp: Date = Date()
  ) {
    self.id = id
    self.restaurantID = restaurantID
    self.user = user
    self.rating = rating
    self.comment = comment
    self.images = images
    self.timestamp = timestamp
  }
}
