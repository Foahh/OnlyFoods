//
//  MainTabView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftData
import SwiftUI

struct TabBarMinimizeModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.tabBarMinimizeBehavior(.onScrollDown)
    } else {
      content
    }
  }
}

struct MainTabView: View {
  @Environment(\.modelContext) private var modelContext
  @StateObject private var searchService = SearchService.shared
  @State private var selectedTab = 0

  var body: some View {
    TabView(selection: $selectedTab) {

      Tab("Explore", systemImage: "list.bullet", value: 0) {
        ExploreTabView()

      }

      Tab("Map", systemImage: "map", value: 1) {
        MapTabView()

      }

      Tab("Profile", systemImage: "person.circle", value: 2) {
        ProfileTabView()

      }

      Tab(value: 3, role: .search) {
        SearchView()
      }

    }
    .modifier(TabBarMinimizeModifier())
  }
}

#Preview {
  MainTabView()
    .previewContainerWithUserManager()
}
