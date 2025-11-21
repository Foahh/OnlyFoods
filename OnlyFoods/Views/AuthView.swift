//
//  AuthView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftData
import SwiftUI

struct AuthView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var userManager: UserManager
  @Query private var users: [UserModel]

  @State private var username: String = ""
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Image(systemName: "fork.knife.circle.fill")
          .font(.system(size: 80))
          .foregroundColor(.blue)

        Text("OnlyFoods")
          .font(.largeTitle)
          .fontWeight(.bold)

        Text("Discover restaurants nearby")
          .font(.subheadline)
          .foregroundColor(.secondary)

        VStack(spacing: 16) {
          TextField("Username", text: $username)
            .textFieldStyle(.roundedBorder)
            .autocapitalization(.none)

          if let error = errorMessage {
            Text(error)
              .font(.caption)
              .foregroundColor(.red)
          }

          Button {
            authenticate()
          } label: {
            Text("Continue")
              .font(.headline)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(username.isEmpty ? Color.gray : Color.blue)
              .cornerRadius(10)
          }
          .disabled(username.isEmpty)
        }
        .padding(.horizontal, 32)

        Spacer()
      }
      .padding()
      .navigationTitle("Welcome")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
    }
  }

  private func authenticate() {
    let normalizedUsername = username.lowercased()

    // Check if user already exists
    if let existingUser = users.first(where: { $0.username.lowercased() == normalizedUsername }) {
      // User exists, log them in
      userManager.setCurrentUser(existingUser)
      errorMessage = nil
      dismiss()
      print("Login successful for user: \(existingUser.username)")
    } else {
      // User doesn't exist, create new account
      let newUser = UserModel(username: username)
      modelContext.insert(newUser)
      userManager.setCurrentUser(newUser)
      errorMessage = nil
      dismiss()
      print("Account created and logged in for user: \(newUser.username)")
    }
  }
}

#Preview {
  AuthView()
    .previewContainer()
}
