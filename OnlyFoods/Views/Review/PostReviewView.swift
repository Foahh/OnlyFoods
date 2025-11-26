//
//  PostReviewView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import CoreImage
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

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 12) {
          ReviewHeaderCard(restaurant: restaurant, user: user)
          ReviewRatingSection(rating: $rating)
          ReviewCommentSection(comment: $comment)
          ReviewPhotosSection(images: $images)
        }
        .padding(.vertical, 24)
        .padding(.horizontal)
      }
      .navigationTitle("Share a Review")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          CancelButton(action: dismiss.callAsFunction)
        }
        ToolbarItem(placement: .confirmationAction) {
          ConfirmButton(action: submitReview)
        }
      }
    }
  }

  private func submitReview() {
    let review = ReviewModel(
      restaurantID: restaurant.id,
      user: user,
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
      RestaurantIconView()
      PostRestaurantInfoView(restaurant: restaurant, user: user)
      Spacer()
    }
    .padding()
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
  }
}

private struct RestaurantIconView: View {
  var body: some View {
    ZStack {
      Circle()
        .fill(Color.accentColor.opacity(0.15))
        .frame(width: 58, height: 58)
      Image(systemName: "fork.knife.circle.fill")
        .font(.system(size: 34))
        .foregroundColor(.accentColor)
    }
  }
}

private struct PostRestaurantInfoView: View {
  let restaurant: RestaurantModel
  let user: UserModel

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(restaurant.name)
        .font(.headline)
        .lineLimit(2)
      Text("Reviewing as \(user.username)")
        .font(.subheadline)
        .foregroundColor(.secondary)
    }
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

private struct FilterPickerItem: Identifiable {
  let id: Int
  let image: UIImage
  let filter: ImageFilter
}

private struct ReviewPhotoCarousel: View {
  let originalImages: [UIImage]
  let filters: [ImageFilter]
  let onRemove: (Int) -> Void
  let onFilterChange: (Int, ImageFilter) -> Void
  @State private var filterPickerItem: FilterPickerItem? = nil

  var body: some View {
    VStack(spacing: 12) {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 14) {
          ForEach(Array(originalImages.enumerated()), id: \.offset) { index, originalImage in
            PhotoThumbnailItem(
              image: originalImage,
              filter: filters[safe: index] ?? .none,
              onTap: {
                filterPickerItem = FilterPickerItem(
                  id: index,
                  image: originalImage,
                  filter: filters[safe: index] ?? .none
                )
              },
              onRemove: {
                onRemove(index)
              }
            )
          }
        }
        .padding(.vertical, 4)
      }

      if !originalImages.isEmpty {
        PhotoCarouselHint()
      }
    }
    .sheet(item: $filterPickerItem) { item in
      FilterPickerView(
        originalImage: item.image,
        selectedFilter: item.filter,
        onFilterSelected: { filter in
          onFilterChange(item.id, filter)
          filterPickerItem = nil
        }
      )
    }
  }
}

private struct PhotoThumbnailItem: View {
  let image: UIImage
  let filter: ImageFilter
  let onTap: () -> Void
  let onRemove: () -> Void

  private var displayImage: UIImage {
    ImageFilterUtility.applyFilter(filter, to: image) ?? image
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Button(action: onTap) {
        Image(uiImage: displayImage)
          .resizable()
          .scaledToFill()
          .frame(width: 120, height: 120)
          .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
          .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
          .overlay(alignment: .center) {
            if filter != .none {
              Image(systemName: filter.icon)
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(6)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
                .padding(6)
            }
          }
      }

      RemovePhotoButton(action: onRemove)
    }
  }
}

private struct RemovePhotoButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
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

private struct PhotoCarouselHint: View {
  var body: some View {
    Text("Tap any photo to customize filters")
      .font(.caption)
      .foregroundColor(.secondary)
  }
}

private struct ReviewRatingSection: View {
  @Binding var rating: Int

  var body: some View {
    ReviewSectionContainer(
      title: "Rating",
      icon: "star.hexagon",
      accentColor: Color(.systemYellow)
    ) {
      VStack(alignment: .leading, spacing: 8) {
        PostStarRatingView(rating: $rating)
        RatingLabel(rating: rating)
      }
    }
  }
}

private struct PostStarRatingView: View {
  @Binding var rating: Int

  var body: some View {
    HStack(spacing: 8) {
      ForEach(1...5, id: \.self) { star in
        StarRatingButton(
          star: star,
          isSelected: star <= rating,
          isHighlighted: star == rating,
          action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              rating = star
            }
          }
        )
      }
    }
  }
}

private struct StarRatingButton: View {
  let star: Int
  let isSelected: Bool
  let isHighlighted: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "star.fill")
        .font(.title2)
        .foregroundStyle(isSelected ? Color.yellow : Color(.systemGray4))
        .scaleEffect(isHighlighted ? 1.1 : 1.0)
    }
    .accessibilityLabel("\(star) star rating")
  }
}

private struct RatingLabel: View {
  let rating: Int

  private var label: String {
    switch rating {
    case 5: return "Loved it"
    case 4: return "Great"
    case 3: return "Okay"
    case 2: return "Needs work"
    default: return "Avoid"
    }
  }

  var body: some View {
    Text(label)
      .font(.subheadline)
      .fontWeight(.medium)
      .foregroundColor(.secondary)
  }
}

private struct ReviewCommentSection: View {
  @Binding var comment: String

  var body: some View {
    ReviewSectionContainer(
      title: "Your Review",
      icon: "text.quote",
      accentColor: Color(.systemOrange)
    ) {
      CommentEditor(comment: $comment)
    }
  }
}

private struct CommentEditor: View {
  @Binding var comment: String
  @FocusState private var isFocused: Bool

  private var trimmedCount: Int {
    comment.trimmingCharacters(in: .whitespacesAndNewlines).count
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      if trimmedCount == 0 {
        CommentPlaceholder()
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
          isFocused ? Color.accentColor.opacity(0.5) : Color.clear,
          lineWidth: 1
        )
    }
  }
}

private struct CommentPlaceholder: View {
  var body: some View {
    Text("Share what made this visit special, standout dishes, vibe...")
      .foregroundColor(.secondary)
      .padding(.horizontal, 14)
      .padding(.vertical, 16)
  }
}

private struct ReviewPhotosSection: View {
  @Binding var images: [String]

  @State private var originalImages: [UIImage] = []
  @State private var imageFilters: [ImageFilter] = []
  @State private var selectedPhotoItems: [PhotosPickerItem] = []
  @State private var selectedUIImage: UIImage? = nil
  @State private var showGalleryPicker = false
  @State private var showCameraPicker = false
  @State private var showCameraUnavailableAlert = false
  @State private var cameraAlertMessage = ""

  var body: some View {
    ReviewSectionContainer(
      title: "Photos",
      icon: "camera.fill",
      accentColor: Color.accentColor
    ) {
      VStack(alignment: .leading, spacing: 12) {
        if originalImages.isEmpty {
          EmptyPhotoState()
        } else {
          ReviewPhotoCarousel(
            originalImages: originalImages,
            filters: imageFilters,
            onRemove: removePreview,
            onFilterChange: updateFilter
          )
        }

        PhotoActionButtons(
          photoCount: originalImages.count,
          selectedPhotoItems: $selectedPhotoItems,
          selectedUIImage: $selectedUIImage,
          showCameraPicker: $showCameraPicker,
          showCameraUnavailableAlert: $showCameraUnavailableAlert,
          cameraAlertMessage: $cameraAlertMessage
        )
      }
    }
    .sheet(isPresented: $showGalleryPicker) {
      ImagePickerGallery(image: $selectedUIImage)
    }
    .fullScreenCover(isPresented: $showCameraPicker) {
      ImagePickerCamera(image: $selectedUIImage)
        .ignoresSafeArea(.all)
    }
    .alert("Camera Not Available", isPresented: $showCameraUnavailableAlert) {
      Button("OK", role: .cancel) {
        showCameraUnavailableAlert = false
      }
    } message: {
      Text(cameraAlertMessage)
    }
    .onChange(of: selectedPhotoItems) { _, newItems in
      handlePhotoItemsSelection(newItems)
    }
    .onChange(of: selectedUIImage) { _, newValue in
      handleUIImageSelection(newValue)
    }
  }

  private func handlePhotoItemsSelection(_ items: [PhotosPickerItem]) {
    originalImages.removeAll()
    imageFilters.removeAll()
    images.removeAll()

    for item in items.prefix(5) {
      Task {
        if let data = try? await item.loadTransferable(type: Data.self),
          let uiImage = UIImage(data: data)
        {
          await MainActor.run {
            originalImages.append(uiImage)
            imageFilters.append(.none)
            let base64 = data.base64EncodedString()
            images.append(base64)
          }
        }
      }
    }
  }

  private func handleUIImageSelection(_ uiImage: UIImage?) {
    guard let uiImage = uiImage else { return }

    guard originalImages.count < 5 else {
      selectedUIImage = nil
      return
    }

    originalImages.append(uiImage)
    imageFilters.append(.none)

    if let filteredImage = ImageFilterUtility.applyFilter(.none, to: uiImage),
      let data = filteredImage.jpegData(compressionQuality: 0.8)
    {
      let base64 = data.base64EncodedString()
      images.append(base64)
    }

    selectedUIImage = nil
  }

  private func removePreview(at index: Int) {
    guard originalImages.indices.contains(index) else { return }
    withAnimation(.easeInOut) {
      originalImages.remove(at: index)
      if imageFilters.indices.contains(index) {
        imageFilters.remove(at: index)
      }
      if images.indices.contains(index) {
        images.remove(at: index)
      }
    }
  }

  private func updateFilter(at index: Int, to filter: ImageFilter) {
    guard originalImages.indices.contains(index) else { return }

    // Update filter
    if imageFilters.indices.contains(index) {
      imageFilters[index] = filter
    } else {
      while imageFilters.count <= index {
        imageFilters.append(.none)
      }
      imageFilters[index] = filter
    }

    // Apply filter and update base64 image
    if let filteredImage = ImageFilterUtility.applyFilter(filter, to: originalImages[index]),
      let data = filteredImage.jpegData(compressionQuality: 0.8)
    {
      let base64 = data.base64EncodedString()
      if images.indices.contains(index) {
        images[index] = base64
      } else {
        while images.count <= index {
          images.append("")
        }
        images[index] = base64
      }
    }
  }
}

private struct PhotoActionButtons: View {
  let photoCount: Int
  @Binding var selectedPhotoItems: [PhotosPickerItem]
  @Binding var selectedUIImage: UIImage?
  @Binding var showCameraPicker: Bool
  @Binding var showCameraUnavailableAlert: Bool
  @Binding var cameraAlertMessage: String

  var body: some View {
    VStack(spacing: 12) {
      LibraryPhotoPickerButton(selection: $selectedPhotoItems)
      CameraButton(
        photoCount: photoCount,
        selectedUIImage: $selectedUIImage,
        showCameraPicker: $showCameraPicker,
        showCameraUnavailableAlert: $showCameraUnavailableAlert,
        cameraAlertMessage: $cameraAlertMessage
      )
    }
  }
}

private struct LibraryPhotoPickerButton: View {
  @Binding var selection: [PhotosPickerItem]

  var body: some View {
    PhotosPicker(
      selection: $selection,
      maxSelectionCount: 5,
      matching: .images
    ) {
      Label("Select from Library", systemImage: "photo.fill.on.rectangle.fill")
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
  }
}

private struct CameraButton: View {
  let photoCount: Int
  @Binding var selectedUIImage: UIImage?
  @Binding var showCameraPicker: Bool
  @Binding var showCameraUnavailableAlert: Bool
  @Binding var cameraAlertMessage: String

  var body: some View {
    Button(action: handleCameraTap) {
      Label("Take a Photo", systemImage: "camera.fill")
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.accentColor.opacity(0.15))
        .foregroundColor(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    .disabled(photoCount >= 5)
  }

  private func handleCameraTap() {
    if photoCount >= 5 {
      cameraAlertMessage = "You can only add up to 5 photos. Remove some photos to add more."
      showCameraUnavailableAlert = true
      return
    }

    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      selectedUIImage = nil
      showCameraPicker = true
    } else {
      cameraAlertMessage = "Use a device with a camera or select from library."
      showCameraUnavailableAlert = true
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

private struct CancelButton: View {
  let action: () -> Void

  var body: some View {
    Button(role: .cancel, action: action) {
      Image(systemName: "chevron.left")
    }
  }
}

extension Array {
  subscript(safe index: Int) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}
