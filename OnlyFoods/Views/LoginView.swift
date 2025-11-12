//
//  LoginView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftData
import SwiftUI

struct LoginView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Query private var users: [UserModel]

  @State private var username: String = ""
  @State private var isCreatingAccount = false
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
            if isCreatingAccount {
              createAccount()
            } else {
              login()
            }
          } label: {
            Text(isCreatingAccount ? "Create Account" : "Login")
              .font(.headline)
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(username.isEmpty ? Color.gray : Color.blue)
              .cornerRadius(10)
          }
          .disabled(username.isEmpty)

          Button {
            isCreatingAccount.toggle()
            errorMessage = nil
          } label: {
            Text(
              isCreatingAccount
                ? "Already have an account? Login" : "Don't have an account? Sign up"
            )
            .font(.subheadline)
            .foregroundColor(.blue)
          }
        }
        .padding(.horizontal, 32)

        Spacer()
      }
      .padding()
      .navigationTitle(isCreatingAccount ? "Sign Up" : "Login")
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

  private func login() {
    if let user = users.first(where: { $0.username.lowercased() == username.lowercased() }) {
      // In a real app, you would set this as the current authenticated user
      // For now, we'll just dismiss
      errorMessage = nil
      dismiss()
      print("Login successful for user: \(user.username)")
    } else {
      errorMessage = "User not found. Please create an account."
    }
  }

  private func createAccount() {
    if users.contains(where: { $0.username.lowercased() == username.lowercased() }) {
      errorMessage = "Username already taken"
      return
    }

    let newUser = UserModel(username: username)
    modelContext.insert(newUser)
    errorMessage = nil

    // In a real app, you would set this as the current authenticated user
    dismiss()
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: UserModel.self, configurations: config)

  return LoginView()
    .modelContainer(container)
}
