//
//  GlassEffect.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

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
