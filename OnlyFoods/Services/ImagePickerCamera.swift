//
//  ImagePickerCamera.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/23.
//

import Foundation
import SwiftUI
import UIKit

struct ImagePickerCamera: UIViewControllerRepresentable {

  @Environment(\.dismiss) private var dismiss
  @Binding var image: UIImage?

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    picker.mediaTypes = ["public.image"]
    picker.cameraCaptureMode = .photo
    picker.modalPresentationStyle = .fullScreen
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
    uiViewController.sourceType = .camera
    uiViewController.cameraCaptureMode = .photo
    uiViewController.modalPresentationStyle = .fullScreen
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    let parent: ImagePickerCamera
    init(parent: ImagePickerCamera) {
      self.parent = parent
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let uiImage = info[.originalImage] as? UIImage {
        parent.image = uiImage
      }
      parent.dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      parent.dismiss()
    }
  }
}

