//
//  RestaurantMapView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/23.
//

import CoreLocation
import MapKit
import SwiftUI

struct RestaurantMapView: View {
  let restaurant: RestaurantModel
  @State private var cameraPosition: MapCameraPosition
  @State private var showLookAround = false
  @State private var lookAroundScene: MKLookAroundScene?
  @State private var isCheckingLookAround = false
  @State private var locationManager = LocationManager()
  @Environment(\.dismiss) private var dismiss

  init(restaurant: RestaurantModel) {
    self.restaurant = restaurant
    let coordinate = CLLocationCoordinate2D(
      latitude: restaurant.latitude,
      longitude: restaurant.longitude
    )
    let region = MKCoordinateRegion(
      center: coordinate,
      span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    _cameraPosition = State(initialValue: .region(region))
  }

  var body: some View {
    NavigationStack {
      RestaurantMapContent(
        restaurant: restaurant,
        cameraPosition: $cameraPosition
      )
      .navigationTitle(restaurant.name)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: {
            dismiss()
          }) {
            Image(systemName: "xmark")
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          OpenInMapsButton(restaurant: restaurant)
        }
      }
      .overlay(alignment: .bottomTrailing) {
        MapBottomToolbar(
          restaurant: restaurant,
          cameraPosition: $cameraPosition,
          locationManager: locationManager,
          showLookAround: $showLookAround,
          lookAroundScene: $lookAroundScene,
          isCheckingLookAround: $isCheckingLookAround
        )
        .padding(.trailing, 15)
      }
      .overlay(alignment: .bottom) {
        if showLookAround, let scene = lookAroundScene {
          LookAroundOverlayView(scene: scene, showLookAround: $showLookAround)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showLookAround)
    }
  }
}

struct RestaurantMapContent: View {
  let restaurant: RestaurantModel
  @Binding var cameraPosition: MapCameraPosition

  private var restaurantCoordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: restaurant.latitude,
      longitude: restaurant.longitude
    )
  }

  var body: some View {
    Map(position: $cameraPosition) {
      UserAnnotation()
      Annotation(
        restaurant.name,
        coordinate: restaurantCoordinate
      ) {
        RestaurantMapPinView()
      }
    }
    .mapStyle(.standard)
  }
}

struct OpenInMapsButton: View {
  let restaurant: RestaurantModel

  private var restaurantCoordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: restaurant.latitude,
      longitude: restaurant.longitude
    )
  }

  var body: some View {
    Button(action: openInMaps) {
      Image(systemName: "arrow.triangle.turn.up.right.diamond")
        .font(.headline)
    }
  }

  private func openInMaps() {
    let mapItem = MKMapItem(
      placemark: MKPlacemark(coordinate: restaurantCoordinate)
    )
    mapItem.name = restaurant.name
    mapItem.openInMaps()
  }
}

struct LookAroundView: UIViewControllerRepresentable {
  let scene: MKLookAroundScene

  func makeUIViewController(context: Context) -> MKLookAroundViewController {
    let viewController = MKLookAroundViewController(scene: scene)

    viewController.view.layer.cornerRadius = 16
    viewController.view.layer.masksToBounds = true
    return viewController
  }

  func updateUIViewController(_ uiViewController: MKLookAroundViewController, context: Context) {
    // No updates needed
  }
}

struct LookAroundOverlayView: View {
  let scene: MKLookAroundScene
  @Binding var showLookAround: Bool

  var body: some View {
    ZStack(alignment: .topTrailing) {
      LookAroundView(scene: scene)
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 16))

      Button(action: {
        showLookAround = false
      }) {
        Image(systemName: "xmark")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.primary)
          .frame(width: 28, height: 28)
          .background(.ultraThinMaterial, in: Circle())
      }
      .buttonStyle(.plain)
      .padding(12)
    }
    .padding(20)
    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 10)
  }
}

struct RestaurantMapPinView: View {
  var body: some View {
    VStack(spacing: 0) {
      Image(systemName: "mappin.circle.fill")
        .font(.system(size: 32, weight: .medium))
        .foregroundStyle(.red)
        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
  }
}

// https://www.youtube.com/watch?v=4RWJlgimoc8
struct MapBottomToolbar: View {
  let restaurant: RestaurantModel
  @Binding var cameraPosition: MapCameraPosition
  let locationManager: LocationManager
  @Binding var showLookAround: Bool
  @Binding var lookAroundScene: MKLookAroundScene?
  @Binding var isCheckingLookAround: Bool

  private var restaurantCoordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(
      latitude: restaurant.latitude,
      longitude: restaurant.longitude
    )
  }

  var body: some View {
    VStack(spacing: 35) {
      Button {
        centerOnUserLocation()
      } label: {
        Image(systemName: "location.fill")
      }

      Button {
        Task {
          await handleLookAroundTap()
        }
      } label: {
        if isCheckingLookAround {
          ProgressView().scaleEffect(0.8)
        } else {
          Image(systemName: "binoculars.fill")
        }
      }
      .disabled(isCheckingLookAround)
      .task {
        await checkLookAroundAvailability()
      }
    }
    .font(.title3)
    .foregroundStyle(.primary)
    .padding(.vertical, 20)
    .padding(.horizontal, 12)
    .modifier(GlassEffectInteractiveModifier(tint: nil))
  }

  private func handleLookAroundTap() async {
    // If we already have a scene, show it immediately
    if lookAroundScene != nil {
      await MainActor.run {
        showLookAround = true
      }
      return
    }

    // Otherwise, check availability
    await checkLookAroundAvailability()
  }

  private func checkLookAroundAvailability() async {
    guard lookAroundScene == nil else { return }

    await MainActor.run {
      isCheckingLookAround = true
    }

    let request = MKLookAroundSceneRequest(coordinate: restaurantCoordinate)

    await withCheckedContinuation { continuation in
      request.getSceneWithCompletionHandler { scene, error in
        Task { @MainActor in
          isCheckingLookAround = false
          if let scene = scene {
            lookAroundScene = scene
          } else if let error = error {
            print("Look Around unavailable: \(error.localizedDescription)")
          }
          continuation.resume()
        }
      }
    }
  }

  private func centerOnUserLocation() {
    let userCoordinate = locationManager.region.center
    let region = MKCoordinateRegion(
      center: userCoordinate,
      span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    cameraPosition = .region(region)
  }
}

#Preview {
  RestaurantMapView(
    restaurant: RestaurantModel(
      id: "test-restaurant-id",
      name: "Sample Restaurant",
      latitude: 22.3193,
      longitude: 114.1694,
      images: [],
      categories: ["Italian", "Wine Bar"],
      addressString: "123 Sample St, Central, Hong Kong"
    )
  )
}
