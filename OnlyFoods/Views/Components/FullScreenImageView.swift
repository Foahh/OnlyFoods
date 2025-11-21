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
    ZStack {
      Color.black.ignoresSafeArea()

      fullScreenContent
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()

      VStack {
        HStack {
          Spacer()
          Button {
            dismiss()
          } label: {
            ZStack {
              Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 44, height: 44)
              Image(systemName: "xmark")
                .foregroundStyle(.white)
            }
          }
          .modifier(GlassEffectModifier())
          .padding(.top, 8)
          .padding(.trailing, 8)
          .accessibilityLabel("Close")
        }
        Spacer()
      }
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

#Preview {
  FullScreenImageView(
    imageSource: "https://picsum.photos/800/1200"
  )
}
