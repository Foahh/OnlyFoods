//
//  ImageFilterPickerView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/23.
//

import SwiftUI
import UIKit

struct FilterPickerView: View {
  let originalImage: UIImage
  @State var selectedFilter: ImageFilter
  let onFilterSelected: (ImageFilter) -> Void
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Spacer()

        FilterPreviewView(
          image: originalImage,
          filter: selectedFilter
        )

        Spacer()

        FilterOptionsScrollView(
          originalImage: originalImage,
          selectedFilter: $selectedFilter
        )
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      .padding(.vertical)
      .navigationTitle("Choose Filter")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        FilterPickerToolbar(
          selectedFilter: selectedFilter,
          onCancel: { dismiss() },
          onConfirm: { onFilterSelected(selectedFilter) }
        )
      }
    }
  }
}

private struct FilterPreviewView: View {
  let image: UIImage
  let filter: ImageFilter

  var body: some View {
    if let filteredImage = ImageFilterUtility.applyFilter(filter, to: image) {
      Image(uiImage: filteredImage)
        .resizable()
        .scaledToFit()
        .frame(maxHeight: 400)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(radius: 8)
        .padding(.horizontal)
    }
  }
}

private struct FilterOptionsScrollView: View {
  let originalImage: UIImage
  @Binding var selectedFilter: ImageFilter

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 16) {
        ForEach(ImageFilter.allCases) { filter in
          FilterOptionView(
            filter: filter,
            isSelected: selectedFilter == filter,
            previewImage: originalImage
          ) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
              selectedFilter = filter
            }
          }
        }
      }
      .padding(.horizontal)
    }
  }
}

private struct FilterOptionView: View {
  let filter: ImageFilter
  let isSelected: Bool
  let previewImage: UIImage
  let onTap: () -> Void

  var body: some View {
    VStack(spacing: 8) {
      FilterOptionImageView(
        image: previewImage,
        filter: filter,
        isSelected: isSelected
      )

      FilterOptionLabel(
        text: filter.displayName,
        isSelected: isSelected
      )
    }
    .onTapGesture {
      onTap()
    }
  }
}

private struct FilterOptionImageView: View {
  let image: UIImage
  let filter: ImageFilter
  let isSelected: Bool

  var body: some View {
    if let filteredPreview = ImageFilterUtility.applyFilter(filter, to: image) {
      Image(uiImage: filteredPreview)
        .resizable()
        .scaledToFill()
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: 12)
            .strokeBorder(
              isSelected ? Color.accentColor : Color.clear,
              lineWidth: 3
            )
        }
        .shadow(
          color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.1),
          radius: isSelected ? 8 : 4
        )
    }
  }
}

private struct FilterOptionLabel: View {
  let text: String
  let isSelected: Bool

  var body: some View {
    Text(text)
      .font(.caption)
      .fontWeight(isSelected ? .semibold : .regular)
      .foregroundColor(isSelected ? .accentColor : .primary)
  }
}

private struct FilterPickerToolbar: ToolbarContent {
  let selectedFilter: ImageFilter
  let onCancel: () -> Void
  let onConfirm: () -> Void

  var body: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button(role: .cancel, action: onCancel) {
        Image(systemName: "chevron.left")
      }
    }
    ToolbarItem(placement: .confirmationAction) {
      ConfirmButton(
        icon: "checkmark",
        disabled: selectedFilter == .none,
        action: onConfirm
      )
    }
  }
}
