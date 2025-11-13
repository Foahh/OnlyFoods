//
//  RestaurantModel.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Foundation

struct RestaurantModel: Codable, Identifiable {
  var id: String
  var name: String
  var description: String
  var latitude: Double
  var longitude: Double
  var images: [String]  // URLs or asset names
  var categories: [String]
  var services: [String]?
  var paymentMethods: [String]?
  var contactPhone: String?
  var addressString: String?
  var businessHours: BusinessHours?
  var priceRange: PriceRange?

  init(
    id: String,
    name: String,
    description: String,
    latitude: Double,
    longitude: Double,
    images: [String] = [],
    categories: [String] = [],
    services: [String]? = nil,
    paymentMethods: [String]? = nil,
    contactPhone: String? = nil,
    addressString: String? = nil,
    businessHours: BusinessHours? = nil,
    priceRange: PriceRange? = nil
  ) {
    self.id = id
    self.name = name
    self.description = description
    self.latitude = latitude
    self.longitude = longitude
    self.images = images
    self.categories = categories
    self.services = services
    self.paymentMethods = paymentMethods
    self.contactPhone = contactPhone
    self.addressString = addressString
    self.businessHours = businessHours
    self.priceRange = priceRange
  }

  /// Checks if the restaurant is currently open
  func isCurrentlyOpen() -> Bool {
    guard let businessHours = businessHours else {
      return false
    }
    return businessHours.isCurrentlyOpen()
  }

  /// Checks if the restaurant is open at a specific date
  func isOpen(at date: Date) -> Bool {
    guard let businessHours = businessHours else {
      return false
    }
    return businessHours.isOpen(at: date)
  }

}
