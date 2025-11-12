//
//  MainTabView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftUI

struct MainTabView: View {
  @Environment(\.modelContext) private var modelContext
  @Query private var restaurants: [RestaurantModel]
  @Query private var users: [UserModel]
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {
      ExploreTabView()
        .tabItem {
          Label("Explore", systemImage: "map")
        }
        .tag(0)

      ProfileTabView()
        .tabItem {
          Label("Profile", systemImage: "person.circle")
        }
        .tag(1)
    }
  }
}

#Preview {
  MainTabView()
    .modelContainer(for: [RestaurantModel.self, ReviewModel.self, UserModel.self], inMemory: true)
}
