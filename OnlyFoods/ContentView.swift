//
//  ContentView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftData
import SwiftUI

enum TabSelection: Int, Codable {
  case explore = 0
  case map = 1
  case profile = 2
  case search = 3
}

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext
  @SceneStorage("selectedTab") private var selectedTab: TabSelection = .explore

  var body: some View {
    TabView(selection: $selectedTab) {
      Tab("Explore", systemImage: "list.bullet", value: TabSelection.explore) {
        ExploreTabView()
      }

      Tab("Map", systemImage: "map", value: TabSelection.map) {
        MapTabView()
      }

      Tab("Profile", systemImage: "person.circle", value: TabSelection.profile) {
        ProfileTabView()
      }

      Tab(value: TabSelection.search, role: .search) {
        SearchTabView()
      }
    }
    .modifier(TabBarMinimizeModifier())
  }
}

#Preview {
  ContentView()
    .previewContainer()
}
