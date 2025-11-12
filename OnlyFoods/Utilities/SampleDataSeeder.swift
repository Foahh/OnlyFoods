//
//  SampleDataSeeder.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Foundation
import SwiftData

class SampleDataSeeder {
  static func seedData(modelContext: ModelContext) {
    // Check if data already exists
    let descriptor = FetchDescriptor<RestaurantModel>()
    if let existingRestaurants = try? modelContext.fetch(descriptor), !existingRestaurants.isEmpty {
      return  // Data already seeded
    }

    // Create sample restaurants
    let restaurants = [
      RestaurantModel(
        name: "Golden Dragon Restaurant",
        description:
          "Authentic Cantonese cuisine with a modern twist. Known for our dim sum and roasted meats.",
        latitude: 22.3193,
        longitude: 114.1694,
        images: [],
        cuisineCategory: "Cantonese",
        averageRating: 4.5,
        reviewCount: 128,
        tags: ["Dim Sum", "Roasted Meats", "Family Friendly"]
      ),
      RestaurantModel(
        name: "Tokyo Sushi Bar",
        description:
          "Fresh sushi and sashimi prepared by experienced Japanese chefs. Omakase available.",
        latitude: 22.3210,
        longitude: 114.1700,
        images: [],
        cuisineCategory: "Japanese",
        averageRating: 4.8,
        reviewCount: 95,
        tags: ["Sushi", "Omakase", "Fresh Fish"]
      ),
      RestaurantModel(
        name: "Bella Italia",
        description:
          "Traditional Italian dishes made with imported ingredients. Cozy atmosphere perfect for dates.",
        latitude: 22.3170,
        longitude: 114.1680,
        images: [],
        cuisineCategory: "Italian",
        averageRating: 4.3,
        reviewCount: 76,
        tags: ["Pasta", "Pizza", "Romantic"]
      ),
      RestaurantModel(
        name: "Spice Garden",
        description: "Authentic Indian curries and tandoori dishes. Vegetarian options available.",
        latitude: 22.3220,
        longitude: 114.1710,
        images: [],
        cuisineCategory: "Indian",
        averageRating: 4.6,
        reviewCount: 112,
        tags: ["Curry", "Tandoori", "Vegetarian"]
      ),
      RestaurantModel(
        name: "BBQ Master",
        description: "Korean BBQ with premium meats. All-you-can-eat option available.",
        latitude: 22.3180,
        longitude: 114.1690,
        images: [],
        cuisineCategory: "Korean",
        averageRating: 4.4,
        reviewCount: 89,
        tags: ["BBQ", "All-You-Can-Eat", "Meat"]
      ),
    ]

    // Insert restaurants
    for restaurant in restaurants {
      modelContext.insert(restaurant)
    }

    // Create sample users
    let users = [
      UserModel(username: "foodie123", avatar: nil),
      UserModel(username: "restaurant_lover", avatar: nil),
      UserModel(username: "gourmet_explorer", avatar: nil),
    ]

    for user in users {
      modelContext.insert(user)
    }

    // Create sample reviews
    if let firstRestaurant = restaurants.first, let firstUser = users.first {
      let reviews = [
        ReviewModel(
          restaurantID: firstRestaurant.id,
          userID: firstUser.id,
          rating: 5,
          comment: "Amazing dim sum! The har gow was perfect and the char siu bao was delicious.",
          images: []
        ),
        ReviewModel(
          restaurantID: firstRestaurant.id,
          userID: users[1].id,
          rating: 4,
          comment: "Great food but service was a bit slow during peak hours.",
          images: []
        ),
      ]

      for review in reviews {
        modelContext.insert(review)
        firstRestaurant.reviews?.append(review)
      }

      firstRestaurant.updateRating()
    }

    // Save context
    try? modelContext.save()
  }
}
