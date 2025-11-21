//
//  RestaurantDetailView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import MapKit
import SwiftData
import SwiftUI

struct RestaurantDetailView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var userManager: UserManager
  @Query private var reviews: [ReviewModel]
  @Query private var users: [UserModel]
  @StateObject private var restaurantService = RestaurantService.shared
  @StateObject private var timeService = TimeService.shared
  @State private var showAddReview = false
  @State private var currentRestaurant: RestaurantModel

  private var currentUser: UserModel? {
    userManager.currentUser
  }

  init(restaurant: RestaurantModel) {
    _currentRestaurant = State(initialValue: restaurant)
  }

  var restaurantReviews: [ReviewModel] {
    reviews.filter { $0.restaurantID == currentRestaurant.id }
      .sorted { $0.timestamp > $1.timestamp }
  }

  var rating: RestaurantRating {
    currentRestaurant.rating(from: reviews)
  }

  var isOpenNow: Bool {
    currentRestaurant.isOpen(at: timeService.currentTime)
  }

  private var currentTimeText: String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.locale = Locale.current
    return formatter.string(from: timeService.currentTime)
  }

  private var priceText: String? {
    guard let level = currentRestaurant.priceLevel, level > 0 else { return nil }
    return String(repeating: "$", count: level)
  }

  private var hasPhotoGallery: Bool {
    currentRestaurant.images.count > 1
      || (currentRestaurant.doorImage != nil && !currentRestaurant.images.isEmpty)
  }

  private var favoriteCount: Int {
    RestaurantService.shared.getFavoriteCount(for: currentRestaurant.id, from: users)
  }

  private var visitedCount: Int {
    RestaurantService.shared.getVisitedCount(for: currentRestaurant.id, from: users)
  }

  private func mapURL(for address: String) -> URL? {
    guard let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    else {
      return nil
    }
    return URL(
      string:
        "http://maps.apple.com/?q=\(encoded)&ll=\(currentRestaurant.latitude),\(currentRestaurant.longitude)"
    )
  }

  private func phoneURL(for phone: String) -> URL? {
    let sanitized = phone.filter { "0123456789+".contains($0) }
    guard !sanitized.isEmpty else { return nil }
    return URL(string: "tel://\(sanitized)")
  }

  var body: some View {
    ScrollView {
      VStack {
        VStack(alignment: .leading, spacing: 20) {
          RestaurantDetailHeaderSection(
            restaurantName: currentRestaurant.name,
            rating: rating,
            currentUser: currentUser,
            hasVisited: currentUser?.isVisited(restaurantID: currentRestaurant.id) ?? false,
            isFavorite: currentUser?.isFavorite(restaurantID: currentRestaurant.id) ?? false,
            favoriteCount: favoriteCount,
            visitedCount: visitedCount,
            onToggleVisited: toggleVisitedState,
            onToggleFavorite: toggleFavoriteState
          )

          if !currentRestaurant.categories.isEmpty || priceText != nil {
            RestaurantDetailCategorySection(
              categories: currentRestaurant.categories,
              priceText: priceText
            )
          }

          if hasPhotoGallery {
            RestaurantDetailPhotosSection(
              doorImage: currentRestaurant.doorImage,
              images: currentRestaurant.images
            )
          }

          RestaurantDetailReviewsSection(
            reviews: restaurantReviews,
            users: users,
            currentUser: currentUser,
            onAddReview: { showAddReview = true }
          )

          RestaurantDetailLocationContactSection(
            latitude: currentRestaurant.latitude,
            longitude: currentRestaurant.longitude,
            restaurantName: currentRestaurant.name,
            address: currentRestaurant.addressString,
            mapURL: currentRestaurant.addressString.flatMap { mapURL(for: $0) },
            phone: currentRestaurant.contactPhone,
            phoneURL: currentRestaurant.contactPhone.flatMap { phoneURL(for: $0) }
          )

          if let services = currentRestaurant.services, !services.isEmpty {
            RestaurantDetailTagSection(
              title: "Services & Amenities",
              icon: "takeoutbag.and.cup.and.straw.fill",
              accentColor: .green,
              items: services
            )
          }

          if let paymentMethods = currentRestaurant.paymentMethods, !paymentMethods.isEmpty {
            RestaurantDetailTagSection(
              title: "Payment Methods",
              icon: "creditcard.fill",
              accentColor: .purple,
              items: paymentMethods
            )
          }

          if let businessHours = currentRestaurant.businessHours {
            RestaurantDetailBusinessHoursSection(
              businessHours: businessHours,
              isOpenNow: isOpenNow,
              currentTimeText: currentTimeText
            )
          }
        }
        .padding(20)
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showAddReview) {
      if let user = currentUser {
        AddReviewView(restaurant: currentRestaurant, user: user)
      }
    }
  }
}

extension RestaurantDetailView {
  fileprivate func toggleVisitedState() {
    guard let user = currentUser else { return }

    if user.isVisited(restaurantID: currentRestaurant.id) {
      user.removeVisited(restaurantID: currentRestaurant.id)
    } else {
      user.addVisited(restaurantID: currentRestaurant.id)
    }
  }

  fileprivate func toggleFavoriteState() {
    guard let user = currentUser else { return }

    if user.isFavorite(restaurantID: currentRestaurant.id) {
      user.removeFavorite(restaurantID: currentRestaurant.id)
    } else {
      user.addFavorite(restaurantID: currentRestaurant.id)
    }
  }
}

// MARK: - Sections

struct RestaurantDetailHeaderSection: View {
  let restaurantName: String
  let rating: RestaurantRating
  let currentUser: UserModel?
  let hasVisited: Bool
  let isFavorite: Bool
  let favoriteCount: Int
  let visitedCount: Int
  let onToggleVisited: () -> Void
  let onToggleFavorite: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        Text(restaurantName)
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundStyle(.primary)

        RatingView(rating: rating)
      }

      if currentUser != nil {
        HStack(spacing: 12) {
          RestaurantDetailActionButton(
            title: "Visited",
            systemImage: hasVisited ? "checkmark.circle.fill" : "checkmark.circle",
            isFilled: hasVisited,
            activeColor: .blue,
            onTap: onToggleVisited
          )

          RestaurantDetailActionButton(
            title: "Favorite",
            systemImage: isFavorite ? "heart.fill" : "heart",
            isFilled: isFavorite,
            activeColor: .red,
            onTap: onToggleFavorite
          )
        }
      }

      RestaurantDetailSocialStatsView(
        favoriteCount: favoriteCount,
        visitedCount: visitedCount
      )
    }
  }
}

struct RestaurantDetailSocialStatsView: View {
  let favoriteCount: Int
  let visitedCount: Int

  var body: some View {
    HStack(spacing: 20) {
      RestaurantDetailSocialStat(
        iconFilled: "heart.fill",
        iconEmpty: "heart",
        value: favoriteCount,
        filledColor: .red,
        emptyColor: .secondary.opacity(0.5),
        emptyText: "No favorites yet",
        valueText: { "\($0) favorites" }
      )

      RestaurantDetailSocialStat(
        iconFilled: "checkmark.circle.fill",
        iconEmpty: "checkmark.circle",
        value: visitedCount,
        filledColor: .blue,
        emptyColor: .secondary.opacity(0.5),
        emptyText: "No visits yet",
        valueText: { "\($0) visits" }
      )
    }
  }
}

struct RestaurantDetailSocialStat: View {
  let iconFilled: String
  let iconEmpty: String
  let value: Int
  let filledColor: Color
  let emptyColor: Color
  let emptyText: String
  let valueText: (Int) -> String

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: value > 0 ? iconFilled : iconEmpty)
        .font(.subheadline)
        .foregroundStyle(value > 0 ? filledColor : emptyColor)

      if value > 0 {
        Text(valueText(value))
          .font(.subheadline)
          .foregroundStyle(.secondary)
      } else {
        Text(emptyText)
          .font(.subheadline)
          .foregroundStyle(.secondary.opacity(0.6))
          .italic()
      }
    }
  }
}

struct RestaurantDetailActionButton: View {
  let title: String
  let systemImage: String
  let isFilled: Bool
  let activeColor: Color
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack {
        Image(systemName: systemImage)
          .font(.title3)
        Text(title)
          .font(.headline)
      }
      .frame(maxWidth: .infinity)
      .frame(height: 50)
      .foregroundStyle(isFilled ? .white : activeColor)
      .background(isFilled ? activeColor : activeColor.opacity(0.1))
      .clipShape(Capsule())
    }
  }
}

struct RestaurantDetailCategorySection: View {
  let categories: [String]
  let priceText: String?

  var body: some View {
    CategoryChipsView(
      categories: categories,
      priceText: priceText
    )
  }
}

struct RestaurantDetailTagSection: View {
  let title: String
  let icon: String
  let accentColor: Color
  let items: [String]

  var body: some View {
    InfoSectionCard(
      title: title,
      icon: icon,
      accentColor: accentColor
    ) {
      TagGridView(items: items)
    }
  }
}

struct RestaurantDetailPhotosSection: View {
  let doorImage: String?
  let images: [String]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        if let doorImage,
          let doorImageURL = URL(string: doorImage)
        {
          RestaurantImageItem(url: doorImageURL)
        }

        ForEach(images, id: \.self) { imageURL in
          if let url = URL(string: imageURL) {
            RestaurantImageItem(url: url)
          }
        }
      }
      .padding(.horizontal, 4)
    }
  }
}

struct RestaurantDetailLocationContactSection: View {
  let latitude: Double
  let longitude: Double
  let restaurantName: String
  let address: String?
  let mapURL: URL?
  let phone: String?
  let phoneURL: URL?

  private var hasAddress: Bool {
    address?.isEmpty == false
  }

  private var hasPhone: Bool {
    phone?.isEmpty == false && phoneURL != nil
  }

  private var coordinateText: String {
    let lat = String(format: "%.4f", latitude)
    let lon = String(format: "%.4f", longitude)
    return "\(lat), \(lon)"
  }

  var body: some View {
    InfoSectionCard(
      title: "Location & Contact",
      icon: "map.fill",
      accentColor: .orange
    ) {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 12) {
          if hasAddress, let address {
            InfoRow(
              icon: "mappin.and.ellipse",
              title: "Address",
              detail: address,
              trailing: {
                Button(action: {
                  let mapItem = MKMapItem(
                    placemark: MKPlacemark(
                      coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    ))
                  mapItem.name = restaurantName
                  mapItem.openInMaps()
                }) {
                  Image(systemName: "map.fill")
                    .font(.headline)
                    .padding(10)
                    .background(Color.blue.opacity(0.15))
                    .foregroundStyle(.blue)
                    .clipShape(Circle())
                }
              }
            )
          }

          if hasPhone, let phone,
            let phoneURL
          {
            Divider()
            InfoRow(
              icon: "phone.fill",
              title: "Phone",
              detail: phone,
              trailing: {
                Link(destination: phoneURL) {
                  Image(systemName: "phone.arrow.up.right")
                    .font(.headline)
                    .padding(10)
                    .background(Color.green.opacity(0.15))
                    .foregroundStyle(.green)
                    .clipShape(Circle())
                }
              }
            )
          }
        }
      }
    }
  }
}

struct RestaurantDetailBusinessHoursSection: View {
  let businessHours: BusinessHours
  let isOpenNow: Bool
  let currentTimeText: String

  var body: some View {
    InfoSectionCard(
      title: "Business Hours",
      icon: "clock.badge.checkmark",
      accentColor: .blue
    ) {
      BusinessHoursView(
        businessHours: businessHours,
        isOpenNow: isOpenNow,
        currentTimeText: currentTimeText
      )
    }
  }
}

struct RestaurantDetailReviewsSection: View {
  let reviews: [ReviewModel]
  let users: [UserModel]
  let currentUser: UserModel?
  let onAddReview: () -> Void

  var body: some View {
    InfoSectionCard(
      title: "Reviews",
      icon: "text.bubble.fill",
      accentColor: .indigo,
      headerTrailing: {
        if currentUser != nil {
          Button(action: onAddReview) {
            Label("Post", systemImage: "plus.circle.fill")
              .font(.subheadline.weight(.semibold))
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(Color.blue.opacity(0.12))
              .foregroundStyle(.blue)
              .clipShape(Capsule())
          }
        }
      }
    ) {
      VStack(alignment: .leading, spacing: 16) {
        if reviews.isEmpty {
          RestaurantDetailEmptyReviewsState(
            hasCurrentUser: currentUser != nil
          )
        } else {
          LazyVStack(spacing: 16) {
            ForEach(reviews) { review in
              ReviewRowView(review: review, users: users)
            }
          }
        }
      }
    }
  }
}

struct RestaurantDetailEmptyReviewsState: View {
  let hasCurrentUser: Bool

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "star.bubble")
        .font(.system(size: 48))
        .foregroundStyle(.secondary.opacity(0.5))
      Text("No reviews yet")
        .font(.headline)
        .foregroundStyle(.primary)
      if hasCurrentUser {
        Text("Be the first to review this restaurant!")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 32)
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }
}

struct ReviewRowView: View {
  let review: ReviewModel
  let users: [UserModel]

  var reviewUser: UserModel? {
    users.first { $0.id == review.userID }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // User Info and Rating
      HStack(alignment: .top, spacing: 12) {
        // Avatar
        if let user = reviewUser {
          if let avatar = user.avatar, let avatarURL = URL(string: avatar) {
            AsyncImage(url: avatarURL) { phase in
              switch phase {
              case .empty:
                AvatarPlaceholder()
              case .success(let image):
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
              case .failure:
                AvatarPlaceholder()
              @unknown default:
                AvatarPlaceholder()
              }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
          } else {
            AvatarPlaceholder()
              .frame(width: 44, height: 44)
          }
        } else {
          AvatarPlaceholder()
            .frame(width: 44, height: 44)
        }

        VStack(alignment: .leading, spacing: 6) {
          HStack {
            Text(reviewUser?.username ?? "Anonymous")
              .font(.headline)
              .foregroundStyle(.primary)

            Spacer()

            // Star Rating
            HStack(spacing: 2) {
              ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= review.rating ? "star.fill" : "star")
                  .foregroundStyle(star <= review.rating ? .yellow : .yellow.opacity(0.3))
                  .font(.caption)
              }
            }
          }

          Text(review.timestamp, style: .relative)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      // Review Comment
      if !review.comment.isEmpty {
        Text(review.comment)
          .font(.body)
          .foregroundStyle(.primary)
          .fixedSize(horizontal: false, vertical: true)
      }

      // Review Images
      if !review.images.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(review.images, id: \.self) { imageURL in
              if let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                  switch phase {
                  case .empty:
                    ReviewImagePlaceholder()
                  case .success(let image):
                    image
                      .resizable()
                      .aspectRatio(contentMode: .fill)
                  case .failure:
                    ReviewImagePlaceholder()
                  @unknown default:
                    ReviewImagePlaceholder()
                  }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
              }
            }
          }
        }
      }
    }
    .padding(16)
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(.separator), lineWidth: 0.5)
    )
    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}

struct InfoSectionCard<
  Content: View,
  HeaderTrailing: View
>: View {
  let title: String
  let icon: String
  let accentColor: Color
  @ViewBuilder var headerTrailing: () -> HeaderTrailing
  @ViewBuilder var content: () -> Content

  init(
    title: String,
    icon: String,
    accentColor: Color,
    @ViewBuilder headerTrailing: @escaping () -> HeaderTrailing = { EmptyView() },
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.title = title
    self.icon = icon
    self.accentColor = accentColor
    self.headerTrailing = headerTrailing
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(alignment: .center, spacing: 12) {
        Label {
          Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
        } icon: {
          ZStack {
            Circle()
              .fill(accentColor.opacity(0.15))
              .frame(width: 36, height: 36)
            Image(systemName: icon)
              .font(.subheadline.weight(.semibold))
              .foregroundStyle(accentColor)
          }
        }
        Spacer(minLength: 12)
        headerTrailing()
      }

      content()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.systemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color(.separator), lineWidth: 0.5)
    )
    .cornerRadius(16)
    .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
  }
}

struct InfoRow<Trailing: View>: View {
  let icon: String
  let title: String
  let detail: String
  @ViewBuilder var trailing: () -> Trailing

  init(
    icon: String,
    title: String,
    detail: String,
    @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
  ) {
    self.icon = icon
    self.title = title
    self.detail = detail
    self.trailing = trailing
  }

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: icon)
        .font(.headline)
        .foregroundStyle(.secondary)
        .frame(width: 24, height: 24)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.secondary)
        Text(detail)
          .font(.body)
          .foregroundStyle(.primary)
      }

      Spacer(minLength: 8)
      trailing()
    }
  }
}

struct TagGridView: View {
  let items: [String]

  var body: some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
      ForEach(items, id: \.self) { item in
        Text(item)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(.primary)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .frame(maxWidth: .infinity)
          .background(Color(.systemGray6))
          .clipShape(Capsule())
      }
    }
  }
}

struct BusinessHoursView: View {
  let businessHours: BusinessHours
  let isOpenNow: Bool
  let currentTimeText: String

  private var localizedTimeZone: String {
    let timeZone = TimeZone.current
    if let localizedName = timeZone.localizedName(for: .shortGeneric, locale: Locale.current) {
      return localizedName
    }
    if let abbreviation = timeZone.abbreviation() {
      return abbreviation
    }
    return timeZone.identifier
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label {
          Text(isOpenNow ? "Open Now" : "Closed")
            .font(.subheadline.weight(.semibold))
        } icon: {
          Image(systemName: isOpenNow ? "checkmark.circle.fill" : "xmark.circle.fill")
        }
        .foregroundStyle(isOpenNow ? Color.green : Color.red)

        Spacer()

        Text("Updated \(currentTimeText) • \(localizedTimeZone)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      VStack(spacing: 10) {
        ForEach(1...7, id: \.self) { weekday in
          DayHoursRow(
            dayIndex: weekday,
            dayHours: businessHours.dayHoursForWeekday(weekday)
          )
        }
      }
    }
  }
}

struct DayHoursRow: View {
  let dayIndex: Int
  let dayHours: DayHours?

  private enum BusinessHourDisplayFormatter {
    static let inputFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "HH:mm"
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = TimeZone(secondsFromGMT: 0)
      return formatter
    }()

    static let outputFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.timeStyle = .short
      formatter.dateStyle = .none
      formatter.locale = Locale.current
      formatter.timeZone = TimeZone.current
      return formatter
    }()

    static func formattedTime(_ rawValue: String) -> String {
      guard let date = inputFormatter.date(from: rawValue) else {
        return rawValue
      }
      return outputFormatter.string(from: date)
    }

    static func formattedRange(_ range: TimeRange) -> String {
      "\(formattedTime(range.start)) – \(formattedTime(range.end))"
    }
  }

  private var isToday: Bool {
    Calendar.current.component(.weekday, from: Date()) == dayIndex
  }

  private var dayName: String {
    let formatter = DateFormatter()
    formatter.locale = Locale.current
    return formatter.weekdaySymbols[(dayIndex - 1) % 7]
  }

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text(dayName)
        .font(.subheadline)
        .foregroundStyle(isToday ? .primary : .secondary)
        .frame(width: 90, alignment: .leading)

      Spacer()

      Group {
        if let hours = dayHours {
          if hours.isClosed {
            Text("Closed")
              .font(.subheadline.weight(isToday ? .semibold : .regular))
              .foregroundStyle(.secondary)
          } else if hours.is24hr {
            Text("Open 24 hours")
              .font(.subheadline.weight(isToday ? .semibold : .regular))
              .foregroundStyle(.primary)
          } else if hours.periods.isEmpty {
            Text("Hours not available")
              .font(.subheadline.weight(isToday ? .semibold : .regular))
              .foregroundStyle(.secondary)
          } else {
            VStack(alignment: .leading, spacing: 2) {
              ForEach(hours.periods.indices, id: \.self) { index in
                let period = hours.periods[index]
                Text(BusinessHourDisplayFormatter.formattedRange(period))
                  .font(.subheadline.weight(isToday ? .semibold : .regular))
                  .foregroundStyle(.primary)
              }
            }
          }
        } else {
          Text("Hours not available")
            .font(.subheadline.weight(isToday ? .semibold : .regular))
            .foregroundStyle(.secondary)
        }
      }

    }
    .padding(.vertical, 4)
  }
}

struct RestaurantDetailImageView: View {
  let restaurant: RestaurantModel

  var body: some View {
    Group {
      if let doorImage = restaurant.doorImage, let doorImageURL = URL(string: doorImage) {
        AsyncImage(url: doorImageURL) { phase in
          switch phase {
          case .empty:
            ImagePlaceholder()
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          case .failure:
            ImagePlaceholder()
          @unknown default:
            ImagePlaceholder()
          }
        }
      } else if let firstImage = restaurant.images.first,
        let firstImageURL = URL(string: firstImage)
      {
        AsyncImage(url: firstImageURL) { phase in
          switch phase {
          case .empty:
            ImagePlaceholder()
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          case .failure:
            ImagePlaceholder()
          @unknown default:
            ImagePlaceholder()
          }
        }
      } else {
        ImagePlaceholder()
      }
    }
  }
}

struct RestaurantImageItem: View {
  let url: URL

  var body: some View {
    AsyncImage(url: url) { phase in
      switch phase {
      case .empty:
        ImagePlaceholder()
      case .success(let image):
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
      case .failure:
        ImagePlaceholder()
      @unknown default:
        ImagePlaceholder()
      }
    }
    .frame(width: 200, height: 150)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

struct AvatarPlaceholder: View {
  var body: some View {
    Circle()
      .fill(Color(.systemGray5))
      .overlay {
        Image(systemName: "person.fill")
          .font(.system(size: 20))
          .foregroundStyle(.secondary.opacity(0.6))
      }
  }
}

struct ReviewImagePlaceholder: View {
  var body: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(Color(.systemGray5))
      .overlay {
        Image(systemName: "photo")
          .font(.system(size: 24))
          .foregroundStyle(.secondary.opacity(0.5))
      }
  }
}

#Preview {
  RestaurantDetailView(
    restaurant: RestaurantModel(
      id: "test-restaurant-id",
      name: "Sample Restaurant",
      latitude: 22.3193,
      longitude: 114.1694,
      images: [
        "https://picsum.photos/200/300",
        "https://picsum.photos/200/300",
        "https://picsum.photos/200/300",
        "https://picsum.photos/200/300",
      ],
      categories: ["Italian", "Wine Bar"],
      services: ["Dine-in", "Takeout", "Delivery", "Outdoor Seating"],
      paymentMethods: ["Visa", "Mastercard", "Apple Pay", "Cash"],
      contactPhone: "+1 (555) 123-4567",
      addressString: "123 Sample St, Central, Hong Kong",
      businessHours: BusinessHours(
        days: [
          DayHours(
            dayOfWeek: 2, isClosed: false, is24hr: false,
            periods: [TimeRange(start: "11:30", end: "22:00")]),
          DayHours(
            dayOfWeek: 3, isClosed: false, is24hr: false,
            periods: [TimeRange(start: "11:30", end: "22:00")]),
          DayHours(
            dayOfWeek: 4, isClosed: false, is24hr: false,
            periods: [TimeRange(start: "11:30", end: "23:00")]),
          DayHours(
            dayOfWeek: 5, isClosed: false, is24hr: false,
            periods: [TimeRange(start: "11:30", end: "23:30")]),
          DayHours(
            dayOfWeek: 6, isClosed: false, is24hr: false,
            periods: [TimeRange(start: "10:00", end: "23:30")]),
          DayHours(
            dayOfWeek: 7, isClosed: false, is24hr: false,
            periods: [TimeRange(start: "10:00", end: "22:00")]),
          DayHours(dayOfWeek: 1, isClosed: true, is24hr: false, periods: []),
        ]
      ),
      priceLevel: 3
    )
  )
  .previewContainer(withMockData: true)
}
