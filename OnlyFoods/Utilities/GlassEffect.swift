import SwiftUI

struct GlassEffectModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.glassEffect()
    } else {
      content
    }
  }
}