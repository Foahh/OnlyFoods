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
      content.glassEffect(.regular)
    } else {
      content
    }
  }
}

struct GlassEffectInteractiveModifier: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.glassEffect(.regular.interactive())
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
  let action: () -> Void
  var icon: String = "arrow.up"
  var disabled: Bool = false

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

struct IsSearchableModifier: ViewModifier {
  let isSearchable: Bool
  let prompt: String
  @Binding var searchText: String

  func body(content: Content) -> some View {
    if isSearchable {
      content.searchable(text: $searchText, prompt: prompt)
    } else {
      content
    }
  }
}
