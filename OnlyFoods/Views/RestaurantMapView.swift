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
      ZStack {
        RestaurantMapContent(
          restaurant: restaurant,
          cameraPosition: $cameraPosition
        )

        MapOverlayView(
          restaurant: restaurant,
          showLookAround: $showLookAround,
          lookAroundScene: $lookAroundScene,
          isCheckingLookAround: $isCheckingLookAround
        )
      }
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
      .sheet(isPresented: $showLookAround) {
        if let scene = lookAroundScene {
          LookAroundView(scene: scene)
            .presentationDetents([.large])
        }
      }
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

struct MapOverlayView: View {
  let restaurant: RestaurantModel
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
    VStack {
      Spacer()
      HStack {
        Spacer()
        LookAroundButton(
          showLookAround: $showLookAround,
          lookAroundScene: $lookAroundScene,
          isCheckingLookAround: $isCheckingLookAround,
          coordinate: restaurantCoordinate
        )
        .padding(.trailing, 20)
        .padding(.bottom, 20)
      }
    }
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

struct LookAroundButton: View {
  @Binding var showLookAround: Bool
  @Binding var lookAroundScene: MKLookAroundScene?
  @Binding var isCheckingLookAround: Bool
  let coordinate: CLLocationCoordinate2D

  var body: some View {
    Button(action: {
      Task {
        await handleLookAroundTap()
      }
    }) {
      HStack(spacing: 8) {
        if isCheckingLookAround {
          ProgressView()
            .scaleEffect(0.8)
        } else {
          Image(systemName: "binoculars.fill")
            .font(.headline)
        }
        Text("Look Around")
          .font(.subheadline.weight(.semibold))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
    }
    .disabled(isCheckingLookAround)
    .task {
      await checkLookAroundAvailability()
    }
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

    let request = MKLookAroundSceneRequest(coordinate: coordinate)

    await withCheckedContinuation { continuation in
      request.getSceneWithCompletionHandler { scene, error in
        Task { @MainActor in
          isCheckingLookAround = false
          if let scene = scene {
            lookAroundScene = scene
            showLookAround = true
          } else if let error = error {
            print("Look Around unavailable: \(error.localizedDescription)")
          }
          continuation.resume()
        }
      }
    }
  }
}

struct LookAroundView: UIViewControllerRepresentable {
  let scene: MKLookAroundScene

  func makeUIViewController(context: Context) -> MKLookAroundViewController {
    let viewController = MKLookAroundViewController(scene: scene)
    return viewController
  }

  func updateUIViewController(_ uiViewController: MKLookAroundViewController, context: Context) {
    // No updates needed
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
