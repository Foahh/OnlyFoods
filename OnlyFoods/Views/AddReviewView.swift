//
//  AddReviewView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftData
import SwiftUI

struct AddReviewView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  let restaurant: RestaurantModel
  let user: UserModel

  @State private var rating: Int = 5
  @State private var comment: String = ""
  @State private var images: [String] = []

  var body: some View {
    NavigationStack {
      Form {
        Section("Rating") {
          HStack {
            ForEach(1...5, id: \.self) { star in
              Button {
                rating = star
              } label: {
                Image(systemName: star <= rating ? "star.fill" : "star")
                  .foregroundColor(.yellow)
                  .font(.title2)
              }
            }
          }
        }

        Section("Your Review") {
          TextEditor(text: $comment)
            .frame(minHeight: 150)
        }

        Section("Photos") {
          // TODO: Implement image picker and camera here
          Text("Image picker would go here")
            .foregroundColor(.secondary)
            .font(.caption)
        }
      }
      .navigationTitle("Add Review")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Submit") {
            submitReview()
          }
          .disabled(comment.isEmpty)
        }
      }
    }
  }

  private func submitReview() {
    let review = ReviewModel(
      restaurantID: restaurant.id,
      userID: user.id,
      rating: rating,
      comment: comment,
      images: images
    )

    modelContext.insert(review)

    dismiss()
  }
}

#Preview {
  let config = ModelConfiguration(isStoredInMemoryOnly: true)
  let container = try! ModelContainer(for: ReviewModel.self, UserModel.self, configurations: config)

  AddReviewView(
    restaurant: RestaurantModel(
      name: "Sample Restaurant",
      description: "A great place",
      latitude: 22.3193,
      longitude: 114.1694,
      cuisineCategory: "Italian",
    ),
    user: UserModel(username: "TestUser")
  )
  .modelContainer(container)
}
