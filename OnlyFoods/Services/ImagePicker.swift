//
//  ImagePicker.swift
//  OnlyFoods
//
//  Created by MJIMI_TK8 on 20/11/2025.
//

import Foundation
import SwiftUI

struct ImagePicker:UIViewControllerRepresentable {
  
	var selectedSource: UIImagePickerController.SourceType
	@Environment(\.dismiss) private var dismiss
	@Binding var image:UIImage?
	
	func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker=UIImagePickerController()
		picker.sourceType = selectedSource
		picker.delegate = context.coordinator
		return picker
	}
	
	func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
		
	}
	
	func makeCoordinator() -> Coordinator {
		Coordinator(parent: self)
	}
	
	class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
		let parent: ImagePicker
		init(parent: ImagePicker) {
			self.parent = parent
		}
		
		func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
			if let uiImage=info[.originalImage] as? UIImage {
				parent.image=uiImage
			}
			parent.dismiss()
		}
		
		func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			parent.dismiss()
		}
	}
}
