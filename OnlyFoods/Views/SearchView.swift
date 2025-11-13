//
//  SearchView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import SwiftUI

struct SearchView: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var searchText: String
  @Binding var selectedCategory: String?

  let restaurants: [RestaurantModel]

  var categories: [String] {
    Array(Set(restaurants.flatMap { $0.categories })).sorted()
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        // Search Bar
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundColor(.secondary)
          TextField("Search restaurants...", text: $searchText)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)

        // Category Filter
        VStack(alignment: .leading, spacing: 8) {
          Text("Filter by Category")
            .font(.headline)
            .padding(.horizontal)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              Button {
                selectedCategory = nil
              } label: {
                Text("All")
                  .padding(.horizontal, 16)
                  .padding(.vertical, 8)
                  .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                  .foregroundColor(selectedCategory == nil ? .white : .primary)
                  .cornerRadius(20)
              }

              ForEach(categories, id: \.self) { category in
                Button {
                  selectedCategory = category
                } label: {
                  Text(category)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedCategory == category ? .white : .primary)
                    .cornerRadius(20)
                }
              }
            }
            .padding(.horizontal)
          }
        }

        Spacer()
      }
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  SearchView(
    searchText: .constant(""),
    selectedCategory: .constant(nil),
    restaurants: []
  )
}
