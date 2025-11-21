//
//  PostReviewView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import PhotosUI
import SwiftData
import SwiftUI

struct PostReviewView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  let restaurant: RestaurantModel
  let user: UserModel

  @State private var rating: Int = 5
  @State private var comment: String = ""
  @State private var images: [String] = []

  private let commentMinLength = 15

  private var commentCharacterCount: Int {
    comment.trimmingCharacters(in: .whitespacesAndNewlines).count
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 12) {
          ReviewHeaderCard(restaurant: restaurant, user: user)
          ReviewRatingSection(rating: $rating)
          ReviewCommentSection(
            comment: $comment,
            minLength: commentMinLength
          )
          ReviewPhotosSection(images: $images)
        }
        .padding(.vertical, 24)
        .padding(.horizontal)
      }
      .navigationTitle("Share a Review")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(role: .cancel) {
            dismiss()
          } label: {
            Image(systemName: "xmark")
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          ConfirmButton(action: submitReview)
        }
      }
    }
  }

  private func submitReview() {
    let review: ReviewModel = ReviewModel(
      restaurantID: restaurant.id,
      userID: user.id,
      rating: rating,
      comment: comment.trimmingCharacters(in: .whitespacesAndNewlines),
      images: images
    )

    modelContext.insert(review)

    dismiss()
  }
}

private struct ReviewHeaderCard: View {
  let restaurant: RestaurantModel
  let user: UserModel

  var body: some View {
    HStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(Color.accentColor.opacity(0.15))
          .frame(width: 58, height: 58)
        Image(systemName: "fork.knife.circle.fill")
          .font(.system(size: 34))
          .foregroundColor(.accentColor)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(restaurant.name)
          .font(.headline)
          .lineLimit(2)
        Text("Reviewing as \(user.username)")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      Spacer()
    }
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
  }
}

private struct EmptyPhotoState: View {
  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: "photo.stack")
        .font(.system(size: 36))
        .foregroundColor(.secondary)
      Text("Add your food photos")
        .font(.headline)
      Text("Visuals help others see portions, plating, and vibe.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
  }
}

private struct ReviewPhotoCarousel: View {
  let images: [UIImage]
  let onRemove: (Int) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 14) {
        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
          ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
              .resizable()
              .scaledToFill()
              .frame(width: 120, height: 120)
              .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

              .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
              .clipped()

            Button {
              onRemove(index)
            } label: {
              Image(systemName: "xmark")
                .font(.caption.bold())
                .padding(6)
                .background(.ultraThinMaterial)
                .foregroundColor(.red)
                .clipShape(Circle())
                .shadow(radius: 2)
            }
            .padding(6)
          }
        }
      }
      .padding(.vertical, 4)
    }
  }
}

private struct ReviewRatingSection: View {
  @Binding var rating: Int

  private var ratingLabel: String {
    switch rating {
    case 5:
      return "Loved it"
    case 4:
      return "Great"
    case 3:
      return "Okay"
    case 2:
      return "Needs work"
    default:
      return "Avoid"
    }
  }

  var body: some View {
    ReviewSectionContainer(
      title: "Rating",
      icon: "star.hexagon",
      accentColor: Color(.systemYellow)
    ) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          ForEach(1...5, id: \.self) { star in
            Button {
              withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                rating = star
              }
            } label: {
              Image(systemName: "star.fill")
                .font(.title2)
                .foregroundStyle(star <= rating ? Color.yellow : Color(.systemGray4))
                .scaleEffect(star == rating ? 1.1 : 1.0)
            }
            .accessibilityLabel("\(star) star rating")
          }
        }

        Text(ratingLabel)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
      }
    }
  }
}

private struct ReviewCommentSection: View {
  @Binding var comment: String
  let minLength: Int

  @FocusState private var isFocused: Bool

  private var trimmedCount: Int {
    comment.trimmingCharacters(in: .whitespacesAndNewlines).count
  }

  var body: some View {
    ReviewSectionContainer(
      title: "Your Review",
      icon: "text.quote",
      accentColor: Color(.systemOrange)
    ) {
      ZStack(alignment: .topLeading) {
        if trimmedCount == 0 {
          Text("Share what made this visit special, standout dishes, vibe...")
            .foregroundColor(.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
        }

        TextEditor(text: $comment)
          .focused($isFocused)
          .padding(.horizontal, 10)
          .padding(.vertical, 12)
          .frame(minHeight: 150, alignment: .topLeading)
          .scrollContentBackground(.hidden)
      }
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 16)
          .strokeBorder(
            isFocused ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
      }
    }
  }
}

private struct ReviewPhotosSection: View {
  @Binding var images: [String]

  @State private var previewImages: [UIImage] = []
  @State private var selectedPhotoItems: [PhotosPickerItem] = []
  @State private var selectedUIImage: UIImage? = nil
  @State private var showImagePicker = false
  @State private var selectedImageSource: UIImagePickerController.SourceType = .photoLibrary
  @State private var showCameraUnavailableAlert = false
  @State private var cameraAlertMessage = ""

  var body: some View {
    ReviewSectionContainer(
      title: "Photos",
      icon: "camera.fill",
      accentColor: Color.accentColor
    ) {
      VStack(alignment: .leading, spacing: 12) {
        if previewImages.isEmpty {
          EmptyPhotoState()
        } else {
          ReviewPhotoCarousel(images: previewImages) { index in
            removePreview(at: index)
          }
        }

        photoActions
      }
    }
    .sheet(isPresented: $showImagePicker) {
      ImagePicker(
        selectedSource: selectedImageSource,
        image: $selectedUIImage
      )
    }
    .alert("Camera Not Available", isPresented: $showCameraUnavailableAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(cameraAlertMessage)
    }
    .onChange(of: selectedPhotoItems) { _, newItems in
      previewImages.removeAll()
      images.removeAll()
      for item in newItems.prefix(5) {
        Task {
          if let data = try? await item.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data)
          {
            await MainActor.run {
              previewImages.append(uiImage)
              let base64 = data.base64EncodedString()
              images.append(base64)
            }
          }
        }
      }
    }
    .onChange(of: selectedUIImage) { _, newValue in
      guard let uiImage = newValue else { return }
      previewImages.append(uiImage)
      if let data = uiImage.jpegData(compressionQuality: 0.8) {
        let base64 = data.base64EncodedString()
        images.append(base64)
      }
    }
  }

  private var photoActions: some View {
    VStack(spacing: 12) {
      PhotosPicker(
        selection: $selectedPhotoItems,
        maxSelectionCount: 5,
        matching: .images
      ) {
        Label("Select from Library", systemImage: "photo.fill.on.rectangle.fill")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color(.tertiarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }

      Button {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
          selectedImageSource = .camera
          selectedUIImage = nil
          showImagePicker = true
        } else {
          cameraAlertMessage = "Use a device with a camera or select from library."
          showCameraUnavailableAlert = true
        }
      } label: {
        Label("Capture Photo", systemImage: "camera.fill")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.accentColor.opacity(0.15))
          .foregroundColor(Color.accentColor)
          .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      }
    }
  }

  private func removePreview(at index: Int) {
    guard previewImages.indices.contains(index) else { return }
    withAnimation(.easeInOut) {
      previewImages.remove(at: index)
      images.remove(at: index)
    }
  }
}

private struct ReviewSectionContainer<
  Content: View,
  HeaderTrailing: View
>: View {
  let title: String
  let icon: String
  let accentColor: Color
  @ViewBuilder var headerTrailing: () -> HeaderTrailing
  @ViewBuilder var content: () -> Content

  init(
    title: String,
    icon: String,
    accentColor: Color,
    @ViewBuilder headerTrailing: @escaping () -> HeaderTrailing = { EmptyView() },
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.icon = icon
    self.accentColor = accentColor
    self.headerTrailing = headerTrailing
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .center, spacing: 12) {
        Label {
          Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
        } icon: {
          ZStack {
            Circle()
              .fill(accentColor.opacity(0.15))
              .frame(width: 36, height: 36)
            Image(systemName: icon)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(accentColor)
          }
        }
        Spacer(minLength: 12)
        headerTrailing()
      }

      content()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.systemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color(.separator), lineWidth: 0.5)
    )
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
  }
}

#Preview {
  PostReviewView(
    restaurant: RestaurantModel(
      id: "mock-restaurant-001",
      name: "Mock Restaurant 001",
      latitude: 22.3193,
      longitude: 114.1694,
      categories: ["Italian"]
    ),
    user: PreviewUtility.createMockUser(username: "mock-user-001")
  )
  .previewContainer()
}
