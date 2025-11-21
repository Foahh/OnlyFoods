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
  @FocusState private var isUsernameFocused: Bool

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        AuthHeaderView()

        VStack(spacing: 20) {
          UsernameInputField(
            username: $username,
            errorMessage: $errorMessage,
            isFocused: $isUsernameFocused,
            onSubmit: {
              if !username.isEmpty {
                authenticate()
              }
            }
          )
        }
        .padding(.horizontal, 24)

        Spacer()
      }
      .padding(.vertical)
      .navigationTitle("Welcome")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        // Auto-focus the username field when view appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          isUsernameFocused = true
        }
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .cancel) {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          ConfirmButton(
            action: authenticate,
            icon: "arrow.right",
            disabled: username.isEmpty
          )
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

struct AuthHeaderView: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "fork.knife.circle.fill")
        .font(.system(size: 80))
        .foregroundColor(.blue)

      Text("OnlyFoods")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("Discover restaurants nearby")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
  }
}

struct UsernameInputField: View {
  @Binding var username: String
  @Binding var errorMessage: String?
  @FocusState.Binding var isFocused: Bool
  var onSubmit: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      TextField("Username", text: $username)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .textContentType(.username)
        .submitLabel(.continue)
        .focused($isFocused)
        .onSubmit {
          onSubmit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
        )

      if let error = errorMessage {
        ErrorMessageView(message: error)
          .animation(.easeInOut, value: errorMessage)
      }
    }
  }
}

struct ErrorMessageView: View {
  let message: String

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "exclamationmark.circle.fill")
        .font(.caption)
      Text(message)
        .font(.caption)
    }
    .foregroundColor(.red)
    .transition(.opacity.combined(with: .move(edge: .top)))
  }
}

#Preview {
  AuthView()
    .previewContainer()
}
