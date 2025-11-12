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
  var tags: [String]

  init(
    id: UUID = UUID(),
    name: String,
    description: String,
    latitude: Double,
    longitude: Double,
    images: [String] = [],
    cuisineCategory: String,
    tags: [String] = []
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.latitude = latitude
    self.longitude = longitude
    self.images = images
    self.cuisineCategory = cuisineCategory
    self.tags = tags
  }

}
