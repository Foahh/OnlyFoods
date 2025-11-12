//
//  RestaurantModel.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Foundation

struct RestaurantModel: Codable, Identifiable {
  var id: UUID
  var name: String
  var description: String
  var latitude: Double
  var longitude: Double
  var images: [String]  // URLs or asset names
  var cuisineCategory: String
  var averageRating: Double
  var reviewCount: Int
  var tags: [String]

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
  }

  func updateRating(from reviews: [ReviewModel]) -> RestaurantModel {
    guard !reviews.isEmpty else {
      return RestaurantModel(
        id: id,
        name: name,
        description: description,
        latitude: latitude,
        longitude: longitude,
        images: images,
        cuisineCategory: cuisineCategory,
        averageRating: 0.0,
        reviewCount: 0,
        tags: tags
      )
    }

    let totalRating = reviews.reduce(0.0) { $0 + Double($1.rating) }
    let newAverageRating = totalRating / Double(reviews.count)

    return RestaurantModel(
      id: id,
      name: name,
      description: description,
      latitude: latitude,
      longitude: longitude,
      images: images,
      cuisineCategory: cuisineCategory,
      averageRating: newAverageRating,
      reviewCount: reviews.count,
      tags: tags
    )
  }
}
