//
//  GlassEffect.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import SwiftUI

struct GlassEffectInteractiveModifier: ViewModifier {
  let tint: Color?
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.glassEffect(.regular.interactive().tint(tint))
    } else {
      content
    }
  }
}

struct TabBarMinimizeModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.tabBarMinimizeBehavior(.onScrollDown)
    } else {
      content
    }
  }
}

struct ConfirmButton: View {
  var icon: String = "arrow.up"
  var disabled: Bool = false
  let action: () -> Void

  var body: some View {
    if #available(iOS 26.0, *) {
      Button(role: .confirm) {
        action()
      } label: {
        Image(systemName: icon)
      }
      .disabled(disabled)
    } else {
      Button(action: action) {
        Image(systemName: icon)
      }
      .disabled(disabled)
    }
  }
}
