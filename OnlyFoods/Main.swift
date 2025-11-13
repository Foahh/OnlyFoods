//
//  OnlyFoodsApp.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/10/30.
//

import SwiftData
import SwiftUI

@main
struct Main: App {
  @StateObject private var userManager = UserManager()

  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      ReviewModel.self,
      UserModel.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  var body: some Scene {
    WindowGroup {
      MainTabView()
        .environmentObject(userManager)
        .onAppear {
          userManager.setModelContext(sharedModelContainer.mainContext)
        }
    }
    .modelContainer(sharedModelContainer)
  }
}
