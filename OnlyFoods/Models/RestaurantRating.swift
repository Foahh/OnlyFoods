//
//  RestaurantRating.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Foundation

struct RestaurantRating {
  let averageRating: Double
  let reviewCount: Int
  
  // Computes the average rating and review count from a list of reviews
  static func compute(from reviews: [ReviewModel]) -> RestaurantRating {
    guard !reviews.isEmpty else {
      return RestaurantRating(averageRating: 0.0, reviewCount: 0)
    }
    
    let totalRating = reviews.reduce(0.0) { $0 + Double($1.rating) }
    let average = totalRating / Double(reviews.count)
    
    return RestaurantRating(
      averageRating: average,
      reviewCount: reviews.count
    )
  }
}

extension RestaurantModel {
  // Computes the average rating and review count for a restaurant from a list of reviews
  func rating(from reviews: [ReviewModel]) -> RestaurantRating {
    let restaurantReviews = reviews.filter { $0.restaurantID == self.id }
    return RestaurantRating.compute(from: restaurantReviews)
  }
}
