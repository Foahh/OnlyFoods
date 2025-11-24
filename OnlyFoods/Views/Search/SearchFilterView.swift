//
//  SearchFilterView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import CoreLocation
import SwiftUI

struct SearchFilterButton: View {
  let restaurantCount: Int
  let hasActiveSearch: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        Image(systemName: "line.3.horizontal.decrease.circle.fill")
          .font(.system(size: 18, weight: .semibold))

        if hasActiveSearch {
          Text("\(restaurantCount) " + "Found")
            .font(.system(size: 16, weight: .bold))
        } else {
          Text("Filters")
            .font(.system(size: 16, weight: .semibold))
        }
      }
      .foregroundStyle(
        hasActiveSearch ? Color.white : Color.primary
      )
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .modifier(GlassEffectInteractiveModifier(tint: hasActiveSearch ? .accentColor : nil))
  }
}

struct SearchFilterView: View {
  @ObservedObject var searchService: SearchService
  @ObservedObject var restaurantService: RestaurantService
  var showSortSection: Bool = true
  var showDistanceSection: Bool = true
  @Environment(\.dismiss) private var dismiss

  var availableCategories: [String] {
    Array(Set(restaurantService.restaurants.flatMap { $0.categories })).sorted()
  }

  var availableServices: [String] {
    Array(
      Set(
        restaurantService.restaurants.compactMap { $0.services }.flatMap { $0 }
      )
    ).sorted()
  }

  var availablePriceLevels: [Int] {
    Array(
      Set(restaurantService.restaurants.compactMap { $0.priceLevel })
    ).sorted()
  }

  var filteredRestaurants: [RestaurantModel] {
    RestaurantFilter.filter(
      restaurants: restaurantService.restaurants,
      searchService: searchService
    )
  }

  var body: some View {
    NavigationStack {
      Form {
        if showSortSection {
          SortSection(searchService: searchService)
        }
        if showDistanceSection {
          DistanceFilterSection(searchService: searchService)
        }
        CategoriesSection(
          categories: availableCategories,
          selectedCategories: $searchService.selectedCategories,
          onToggle: { searchService.toggleCategory($0) }
        )
        ServicesSection(
          services: availableServices,
          selectedServices: $searchService.selectedServices,
          onToggle: { searchService.toggleService($0) }
        )
        AvailabilitySection(isOpenNow: $searchService.isOpenNow)
        PriceLevelSection(
          priceLevels: availablePriceLevels,
          selectedPriceLevels: $searchService.selectedPriceLevels,
          onToggle: { searchService.togglePriceLevel($0) }
        )
      }
      .navigationTitle("Filters")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(role: .destructive) {
            searchService.clearFilters()
          } label: {
            Image(systemName: "xmark")
              .tint(.red)
          }
          .accessibilityLabel("Clear Filters")
          .disabled(!searchService.hasActiveFilters)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          ConfirmButton(
            icon: "checkmark"
          ) {
            dismiss()
          }
          .accessibilityLabel("Apply Filters")
        }
      }
    }
  }
}

struct SortSection: View {
  @ObservedObject var searchService: SearchService

  var body: some View {
    Section("Sort By") {
      Picker("Sort", selection: $searchService.sortOption) {
        ForEach(SortOption.allCases, id: \.self) { option in
          Text(option.rawValue).tag(option)
        }
      }
      .pickerStyle(.menu)

      Picker("Direction", selection: $searchService.sortDirection) {
        ForEach(SortDirection.allCases, id: \.self) { direction in
          Text(direction.rawValue).tag(direction)
        }
      }
      .pickerStyle(.menu)
    }
  }
}

struct DistanceFilterSection: View {
  @ObservedObject var searchService: SearchService

  var body: some View {
    Section("Distance") {
      Picker("Distance", selection: $searchService.selectedDistance) {
        Text("Infinite").tag(DistanceFilter?.none)
        ForEach(DistanceFilter.allCases, id: \.self) { distance in
          Text(distance.displayName).tag(DistanceFilter?.some(distance))
        }
      }
      .pickerStyle(.menu)
    }
  }
}

struct CategoriesSection: View {
  let categories: [String]
  @Binding var selectedCategories: Set<String>
  let onToggle: (String) -> Void
  @State private var searchText: String = ""

  var filteredCategories: [String] {
    if searchText.isEmpty {
      return categories
    }
    return categories.filter { $0.localizedCaseInsensitiveContains(searchText) }
  }

  var body: some View {
    FilterableSection(
      title: "Categories",
      items: categories,
      filteredItems: filteredCategories,
      selectedItems: selectedCategories,
      isEmpty: categories.isEmpty,
      searchText: $searchText,
      searchPlaceholder: "Search categories",
      emptyStateIcon: "tag.slash",
      emptyStateMessage: "No categories available",
      showSearchBar: categories.count > 6,
    ) { category in
      FilterChip(
        text: category,
        isSelected: selectedCategories.contains(category),
        action: {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onToggle(category)
          }
        }
      )
    }
  }
}

struct ServicesSection: View {
  let services: [String]
  @Binding var selectedServices: Set<String>
  let onToggle: (String) -> Void
  @State private var searchText: String = ""

  var filteredServices: [String] {
    if searchText.isEmpty {
      return services
    }
    return services.filter { $0.localizedCaseInsensitiveContains(searchText) }
  }

  var body: some View {
    FilterableSection(
      title: "Services",
      items: services,
      filteredItems: filteredServices,
      selectedItems: selectedServices,
      isEmpty: services.isEmpty,
      searchText: $searchText,
      searchPlaceholder: "Search services",
      emptyStateIcon: "wrench.and.screwdriver.slash",
      emptyStateMessage: "No services available",
      showSearchBar: services.count > 6,
    ) { service in
      FilterChip(
        text: service,
        isSelected: selectedServices.contains(service),
        action: {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            onToggle(service)
          }
        }
      )
    }
  }
}

struct AvailabilitySection: View {
  @Binding var isOpenNow: Bool

  var body: some View {
    Section("Availability") {
      Toggle("Open Now", isOn: $isOpenNow)
    }
  }
}

struct PriceLevelSection: View {
  let priceLevels: [Int]
  @Binding var selectedPriceLevels: Set<Int>
  let onToggle: (Int) -> Void

  var body: some View {
    Section("Price Level") {
      if priceLevels.isEmpty {
        Text("No price levels available")
          .foregroundStyle(.secondary)
          .font(.subheadline)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(priceLevels, id: \.self) { priceLevel in
              PriceLevelChip(
                priceLevel: priceLevel,
                isSelected: selectedPriceLevels.contains(priceLevel),
                action: {
                  onToggle(priceLevel)
                }
              )
            }
          }
          .padding(.vertical, 4)
        }
      }
    }
  }
}

struct FilterChip: View {
  let text: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        if isSelected {
          Image(systemName: "checkmark")
            .font(.caption2)
            .fontWeight(.bold)
        }
        Text(text)
          .font(.subheadline)
          .fontWeight(isSelected ? .semibold : .medium)
          .multilineTextAlignment(.leading)
      }
      .foregroundStyle(isSelected ? .white : .primary)
      .padding(.horizontal, isSelected ? 10 : 12)
      .padding(.vertical, 8)
      .background(
        Capsule()
          .fill(isSelected ? Color.accentColor : Color(.systemGray5))
      )
      .overlay(
        Capsule()
          .stroke(
            isSelected ? Color.accentColor.opacity(0.3) : Color.clear,
            lineWidth: 1
          )
      )
      .scaleEffect(isSelected ? 1.0 : 0.95)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(text)
    .accessibilityHint(isSelected ? "Selected. Tap to deselect." : "Tap to select.")
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }
}

struct PriceLevelChip: View {
  let priceLevel: Int
  let isSelected: Bool
  let action: () -> Void

  var priceSymbols: String {
    String(repeating: "$", count: priceLevel)
  }

  var body: some View {
    Button(action: action) {
      Text(priceSymbols)
        .font(.subheadline)
        .fontWeight(isSelected ? .semibold : .medium)
        .foregroundStyle(isSelected ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          Capsule()
            .fill(isSelected ? Color.accentColor : Color(.systemGray5))
        )
    }
    .buttonStyle(.plain)
  }
}

struct FilterSearchBar: View {
  @Binding var searchText: String
  let placeholder: String

  var body: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(.secondary)
      TextField(placeholder, text: $searchText)
        .textFieldStyle(.plain)
      if !searchText.isEmpty {
        Button {
          searchText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color(.systemGray6))
    .cornerRadius(16)
  }
}

struct FilterEmptyState: View {
  let icon: String
  let message: String

  var body: some View {
    HStack {
      Spacer()
      VStack(spacing: 8) {
        Image(systemName: icon)
          .font(.title2)
          .foregroundStyle(.secondary)
        Text(message)
          .foregroundStyle(.secondary)
          .font(.subheadline)
      }
      .padding(.vertical, 16)
      Spacer()
    }
  }
}

struct FilterGrid<Content: View>: View {
  let items: [String]
  let content: (String) -> Content

  var body: some View {
    ScrollView {
      VStack(spacing: 8) {
        ForEach(items, id: \.self) { item in
          content(item)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .padding(.vertical, 4)
    }
    .frame(maxHeight: items.count > 12 ? 250 : nil)
  }
}

struct CountedSectionHeader: View {
  let title: String
  let count: Int

  var body: some View {
    Text(count == 0 ? title : "\(title) (\(count))")
  }
}

struct ClearAllButton: View {
  let label: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: "xmark.circle")
        Text(label)
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
  }
}

struct FilterableSection<Content: View>: View {
  let title: String
  let items: [String]
  let filteredItems: [String]
  let selectedItems: Set<String>
  let isEmpty: Bool
  @Binding var searchText: String
  let searchPlaceholder: String
  let emptyStateIcon: String
  let emptyStateMessage: String
  let showSearchBar: Bool
  @ViewBuilder let content: (String) -> Content

  var body: some View {
    Section {
      if isEmpty {
        FilterEmptyState(icon: emptyStateIcon, message: emptyStateMessage)
      } else {
        VStack(spacing: 12) {
          if showSearchBar {
            FilterSearchBar(searchText: $searchText, placeholder: searchPlaceholder)
          }

          FilterGrid(items: filteredItems, content: content)
        }
      }
    } header: {
      CountedSectionHeader(title: title, count: selectedItems.count)
    }
  }
}

#Preview {
  SearchFilterView(
    searchService: SearchService(),
    restaurantService: RestaurantService.shared
  )
}
