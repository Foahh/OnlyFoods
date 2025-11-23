//
//  UserManager.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
class UserManager: ObservableObject {
  @Published var currentUser: UserModel?
  @AppStorage("currentUserID") private var currentUserStore: String = ""

  private var modelContext: ModelContext?

  init() {
    // Load current user on initialization if ID is stored
    if !currentUserStore.isEmpty,
      let userID = UUID(uuidString: currentUserStore)
    {
      print("Current user loaded from store: \(userID)")
    }
  }

  func setModelContext(_ context: ModelContext) {
    self.modelContext = context
    loadCurrentUser()
  }

  private func loadCurrentUser() {
    guard let modelContext = modelContext,
      !currentUserStore.isEmpty,
      let userID = UUID(uuidString: currentUserStore)
    else {
      currentUser = nil
      return
    }

    let descriptor = FetchDescriptor<UserModel>(
      predicate: #Predicate { $0.id == userID }
    )

    do {
      let users = try modelContext.fetch(descriptor)
      currentUser = users.first
    } catch {
      print("Error loading current user: \(error)")
      currentUser = nil
    }
  }

  func setCurrentUser(_ user: UserModel) {
    currentUser = user
    currentUserStore = user.id.uuidString
  }

  func logout() {
    currentUser = nil
    currentUserStore = ""
  }

  var isAuthenticated: Bool {
    currentUser != nil
  }
}
