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
    // Check if users already exist
    let userDescriptor = FetchDescriptor<UserModel>()
    if let existingUsers = try? modelContext.fetch(userDescriptor), !existingUsers.isEmpty {
      return  // Data already seeded
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

    // Create sample reviews (using restaurant IDs from JSON)
    // These IDs match the ones in restaurants.json
    let firstRestaurantID = UUID(uuidString: "550e8400-e29b-41d4-a716-446655440000")!
    
    if let firstUser = users.first {
      let reviews = [
        ReviewModel(
          restaurantID: firstRestaurantID,
          userID: firstUser.id,
          rating: 5,
          comment: "Amazing dim sum! The har gow was perfect and the char siu bao was delicious.",
          images: []
        ),
        ReviewModel(
          restaurantID: firstRestaurantID,
          userID: users[1].id,
          rating: 4,
          comment: "Great food but service was a bit slow during peak hours.",
          images: []
        ),
      ]

      for review in reviews {
        modelContext.insert(review)
      }
    }

    // Save context
    try? modelContext.save()
  }
}
