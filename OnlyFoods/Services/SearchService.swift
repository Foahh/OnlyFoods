//
//  SearchService.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import Combine
import Foundation

class SearchService: ObservableObject {
  @Published var searchText: String = ""
  @Published var selectedCategory: String?

  static let shared = SearchService()

  private init() {}

  func clearSearch() {
    searchText = ""
    selectedCategory = nil
  }

  func setCategory(_ category: String?) {
    selectedCategory = category
  }
}
