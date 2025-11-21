import SwiftUI

struct FullScreenImageView<Placeholder: View>: View {
  @Environment(\.dismiss) private var dismiss
  let imageSource: String
  private let placeholder: () -> Placeholder

  init(
    imageSource: String,
    @ViewBuilder placeholder: @escaping () -> Placeholder = { DefaultFullScreenImagePlaceholder() }
  ) {
    self.imageSource = imageSource
    self.placeholder = placeholder
  }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.black.ignoresSafeArea()

      fullScreenContent
        .padding()

      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 32, weight: .semibold))
          .foregroundStyle(.white.opacity(0.9))
          .padding()
      }
      .accessibilityLabel("Close")
    }
  }

  @ViewBuilder
  private var fullScreenContent: some View {
    if let url = URL(string: imageSource), url.scheme != nil {
      AsyncImage(url: url) { phase in
        switch phase {
        case .empty:
          ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
        case .success(let image):
          image
            .resizable()
            .scaledToFit()
        case .failure:
          placeholder()
        @unknown default:
          placeholder()
        }
      }
    } else if let data = Data(base64Encoded: normalizedBase64),
      let decoded = UIImage(data: data)
    {
      Image(uiImage: decoded)
        .resizable()
        .scaledToFit()
    } else {
      placeholder()
    }
  }

  private var normalizedBase64: String {
    guard let range = imageSource.range(of: "base64,") else {
      return imageSource
    }
    return String(imageSource[range.upperBound...])
  }
}

private struct DefaultFullScreenImagePlaceholder: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(Color(.systemGray4))
      .frame(width: 200, height: 200)
      .overlay {
        Image(systemName: "photo")
          .font(.system(size: 32, weight: .medium))
          .foregroundStyle(.secondary.opacity(0.8))
      }
  }
}
