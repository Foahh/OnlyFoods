//
//  MainTabView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftData
import SwiftUI

struct MainTabView: View {
  @Environment(\.modelContext) private var modelContext
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
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: ReviewModel.self, UserModel.self, configurations: config)

  return MainTabView()
    .modelContainer(container)
}
