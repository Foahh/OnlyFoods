//
//  Preview.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import SwiftData
import SwiftUI

/// Preview helper for setting up SwiftUI previews with SwiftData
struct PreviewUtility {
  /// Creates an in-memory ModelContainer for previews
  static func createPreviewContainer(
    withMockData: Bool = false,
    mockUser: UserModel? = nil,
    mockReviews: [ReviewModel]? = nil
  ) -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
      for: ReviewModel.self,
      UserModel.self,
      configurations: config
    )

    if withMockData {
      let context = container.mainContext

      // Create or use provided mock user
      let user = mockUser ?? createMockUser()
      context.insert(user)

      // Create or use provided mock reviews
      let reviews = mockReviews ?? createMockReviews(for: user)
      for review in reviews {
        context.insert(review)
      }
    }

    return container
  }

  /// Creates a mock user for previews
  static func createMockUser(
    username: String = "John Doe",
    avatar: String? = nil,
    favoriteRestaurantIDs: [String] = ["mock-restaurant-001"],
    visitedRestaurantIDs: [String] = ["mock-restaurant-001"]
  ) -> UserModel {
    UserModel(
      username: username,
      avatar: avatar,
      favoriteRestaurantIDs: favoriteRestaurantIDs,
      visitedRestaurantIDs: visitedRestaurantIDs
    )
  }

  /// Creates mock reviews for previews
  static func createMockReviews(for user: UserModel) -> [ReviewModel] {
    [
      ReviewModel(
        restaurantID: "mock-restaurant-001",
        userID: user.id,
        rating: 5,
        comment: "Great food and service!",
        images: [],
        timestamp: Date()
      ),
      ReviewModel(
        restaurantID: "mock-restaurant-001",
        userID: user.id,
        rating: 4,
        comment: "Good experience overall.",
        images: [],
        timestamp: Date().addingTimeInterval(-86400)
      ),
    ]
  }

  /// Creates a UserManager with optional mock user
  static func createPreviewUserManager(withMockUser: Bool = false) -> UserManager {
    let userManager = UserManager()

    if withMockUser {
      let mockUser = createMockUser()
      userManager.setCurrentUser(mockUser)
    }

    return userManager
  }
}

/// View extension for easy preview setup
extension View {
  /// Wraps a view with preview ModelContainer
  func previewContainer(withMockData: Bool = false) -> some View {
    let container = PreviewUtility.createPreviewContainer(withMockData: withMockData)
    let userManager = PreviewUtility.createPreviewUserManager(withMockUser: withMockData)

    // Set modelContext on UserManager so it can load users
    userManager.setModelContext(container.mainContext)

    // If mock data was created, get the user from the container
    if withMockData {
      let context = container.mainContext
      let descriptor = FetchDescriptor<UserModel>()
      if let users = try? context.fetch(descriptor), let mockUser = users.first {
        userManager.setCurrentUser(mockUser)
      }
    }

    return
      self
      .modelContainer(container)
      .environmentObject(userManager)
  }
}
