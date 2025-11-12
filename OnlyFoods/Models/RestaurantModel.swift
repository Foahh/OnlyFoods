//
//  RestaurantModel.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Foundation
import SwiftData

@Model
final class RestaurantModel {
  @Attribute(.unique) var id: UUID
  var name: String
  var description: String
  var latitude: Double
  var longitude: Double
  var images: [String]  // URLs or asset names
  var cuisineCategory: String
  var averageRating: Double
  var reviewCount: Int
  var tags: [String]
  @Relationship(deleteRule: .cascade) var reviews: [ReviewModel]?

  init(
    id: UUID = UUID(),
    name: String,
    description: String,
    latitude: Double,
    longitude: Double,
    images: [String] = [],
    cuisineCategory: String,
    averageRating: Double = 0.0,
    reviewCount: Int = 0,
    tags: [String] = []
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.latitude = latitude
    self.longitude = longitude
    self.images = images
    self.cuisineCategory = cuisineCategory
    self.averageRating = averageRating
    self.reviewCount = reviewCount
    self.tags = tags
    self.reviews = []
  }

  func updateRating() {
    guard let reviews = reviews, !reviews.isEmpty else {
      averageRating = 0.0
      reviewCount = 0
      return
    }

    let totalRating = reviews.reduce(0.0) { $0 + Double($1.rating) }
    averageRating = totalRating / Double(reviews.count)
    reviewCount = reviews.count
  }
}
