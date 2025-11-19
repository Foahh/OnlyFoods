//
//  AddReviewView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftData
import SwiftUI
//import UIKit
import PhotosUI

struct AddReviewView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  let restaurant: RestaurantModel
  let user: UserModel

  @State private var rating: Int = 5
  @State private var comment: String = ""
  @State private var images: [String] = []
	
	@State private var selectedPhotoItems: [PhotosPickerItem] = []
	@State private var selectedPhotosData: [Data] = []

	@State private var selectedUIImage: UIImage? = nil
	@State private var showImagePicker = false
	@State private var selectedImageSource: UIImagePickerController.SourceType = .photoLibrary
	@State private var previewImages: [UIImage] = []

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
			  if !previewImages.isEmpty {
				  ScrollView(.horizontal, showsIndicators: false) {
					  HStack {
						  ForEach(Array(previewImages.enumerated()), id: \.offset) { _, img in
							  Image(uiImage: img)
								  .resizable()
								  .scaledToFill()
								  .frame(width: 80, height: 80)
								  .clipped()
								  .cornerRadius(8)
						  }
					  }
				  }
			  } else {
				  Text("No photos yet")
					  .foregroundColor(.secondary)
					  .font(.caption)
			  }

			  // Mulit-Select：PhotosPicker
			  PhotosPicker(
				  selection: $selectedPhotoItems,
				  maxSelectionCount: nil,           //  5 = max 5 photos ，nil = unlimited
				  matching: .images
			  ) {
				  Label("Select Photos", systemImage: "photo.on.rectangle.angled")
			  }
			  // Single-Select：UIImagePickerController - Photo Library
			  Button {
				  if UIImagePickerController.isSourceTypeAvailable(.camera) {
					  selectedImageSource = .camera
					  selectedUIImage = nil
					  showImagePicker = true
				  } else {
					  print("Camera not available")
				  }
			  } label: {
				  Label("Camera", systemImage: "camera")
			  }
		  }


//		  Section("Photos") {
//			  if !previewImages.isEmpty {
//				  ScrollView(.horizontal, showsIndicators: false) {
//					  HStack {
//						  ForEach(Array(previewImages.enumerated()), id: \.offset) { _, img in
//							  Image(uiImage: img)
//								  .resizable()
//								  .scaledToFill()
//								  .frame(width: 80, height: 80)
//								  .clipped()
//								  .cornerRadius(8)
//						  }
//					  }
//				  }
//			  } else {
//				  Text("No photos yet")
//					  .foregroundColor(.secondary)
//					  .font(.caption)
//			  }
//
//			  Button {
//				  selectedImageSource = .photoLibrary
//				  selectedUIImage = nil
//				  showImagePicker = true
//			  } label: {
//				  Label("Photo Library", systemImage: "photo.on.rectangle")
//			  }
//
//			  Button {
//				  if UIImagePickerController.isSourceTypeAvailable(.camera) {
//					  selectedImageSource = .camera
//				  } else {
//					  selectedImageSource = .photoLibrary
//					  print("Camera not available, fallback to photo library")
//				  }
//				  selectedUIImage = nil
//				  showImagePicker = true
//			  } label: {
//				  Label("Camera", systemImage: "camera")
//			  }
//		  }

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
	  .sheet(isPresented: $showImagePicker) {
		  ImagePicker(
			  selectedSource: selectedImageSource,
			  image: $selectedUIImage
		  )
	  }
		// For PhotosPicker Multi-Select
	  .onChange(of: selectedPhotoItems) { oldItems, newItems in
		  previewImages.removeAll()
		  images.removeAll()
		  for item in newItems {
			  Task {
				  if let data = try? await item.loadTransferable(type: Data.self),
					 let uiImage = UIImage(data: data) {
					  previewImages.append(uiImage)
					  let base64 = data.base64EncodedString()
					  images.append(base64)
				  }
			  }
		  }
	  }
		// For ImagePicker (Camera or single Photo Library)
	  .onChange(of: selectedUIImage) { _, newValue in
		  guard let uiImage = newValue else { return }
		  previewImages.append(uiImage)
		  if let data = uiImage.jpegData(compressionQuality: 0.8) {
			  let base64 = data.base64EncodedString()
			  images.append(base64)
		  }
	  }
//	  .onChange(of: selectedUIImage) { _, newValue in
//		  guard let uiImage = newValue else { return }
//		  previewImages.append(uiImage)
//		  if let data = uiImage.jpegData(compressionQuality: 0.8) {
//			  let base64 = data.base64EncodedString()
//			  images.append(base64)
//		  }
//	  }
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
      id: "test-restaurant-id",
      name: "Sample Restaurant",
      latitude: 22.3193,
      longitude: 114.1694,
      categories: ["Italian"]
    ),
    user: UserModel(username: "TestUser")
  )
  .modelContainer(container)
}
