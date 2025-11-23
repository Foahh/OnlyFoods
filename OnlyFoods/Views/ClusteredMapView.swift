//
//  ClusteredMapView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/24.
//
//  Reference: https://medium.com/@worthbak/clustering-with-mapkit-on-ios-11-a578baada84a

import CoreLocation
import Foundation
import MapKit
import SwiftUI

struct ClusteredMapView: UIViewRepresentable {
  let restaurants: [RestaurantModel]
  let reviews: [ReviewModel]
  let onRestaurantSelected: (RestaurantModel) -> Void
  let onUserLocationUpdate: (CLLocation) -> Void

  func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView()
    mapView.delegate = context.coordinator
    mapView.mapType = .standard
    mapView.showsUserLocation = true
    mapView.userTrackingMode = .followWithHeading

    // Set initial region from location manager
    let initialRegion = context.coordinator.locationManager.region
    mapView.setRegion(initialRegion, animated: false)

    // Update user location initially
    context.coordinator.updateUserLocationIfNeeded()

    // Register annotation views
    mapView.register(
      RestaurantAnnotationView.self,
      forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier
    )
    mapView.register(
      ClusterAnnotationView.self,
      forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier
    )

    return mapView
  }

  func updateUIView(_ mapView: MKMapView, context: Context) {
    // Update user location if it changed
    context.coordinator.updateUserLocationIfNeeded()

    // Update annotations
    let currentAnnotations = mapView.annotations.compactMap { $0 as? RestaurantAnnotation }
    let newRestaurantIDs = Set(restaurants.map { $0.id })

    // Remove annotations that are no longer in the list
    let annotationsToRemove = currentAnnotations.filter {
      !newRestaurantIDs.contains($0.restaurant.id)
    }
    mapView.removeAnnotations(annotationsToRemove)

    // Add new annotations
    let existingIDs = Set(
      mapView.annotations.compactMap { ($0 as? RestaurantAnnotation)?.restaurant.id })
    let annotationsToAdd =
      restaurants
      .filter { !existingIDs.contains($0.id) }
      .map { restaurant in
        let rating = restaurant.rating(from: reviews)
        return RestaurantAnnotation(restaurant: restaurant, rating: rating)
      }

    if !annotationsToAdd.isEmpty {
      mapView.addAnnotations(annotationsToAdd)
    }

    // Update existing annotations if ratings changed
    for annotation in currentAnnotations {
      if let restaurant = restaurants.first(where: { $0.id == annotation.restaurant.id }) {
        let newRating = restaurant.rating(from: reviews)
        if annotation.rating.averageRating != newRating.averageRating
          || annotation.rating.reviewCount != newRating.reviewCount
        {
          // Remove and re-add to trigger view update
          mapView.removeAnnotation(annotation)
          let updatedAnnotation = RestaurantAnnotation(restaurant: restaurant, rating: newRating)
          mapView.addAnnotation(updatedAnnotation)
        }
      }
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, MKMapViewDelegate {
    var parent: ClusteredMapView
    let locationManager = LocationManager()
    private var lastKnownLocation: CLLocationCoordinate2D?

    init(_ parent: ClusteredMapView) {
      self.parent = parent
      super.init()
    }

    func updateUserLocationIfNeeded() {
      let currentCenter = locationManager.region.center

      // Check if location has changed significantly (more than 10 meters)
      if let lastLocation = lastKnownLocation {
        let distance = CLLocation(
          latitude: lastLocation.latitude, longitude: lastLocation.longitude
        )
        .distance(
          from: CLLocation(latitude: currentCenter.latitude, longitude: currentCenter.longitude))

        // Only update if moved more than 10 meters
        if distance < 10 {
          return
        }
      }

      lastKnownLocation = currentCenter
      let location = CLLocation(
        latitude: currentCenter.latitude,
        longitude: currentCenter.longitude
      )
      parent.onUserLocationUpdate(location)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      // User location annotation uses default view
      if annotation is MKUserLocation {
        return nil
      }

      // Cluster annotation
      if annotation is MKClusterAnnotation {
        return mapView.dequeueReusableAnnotationView(
          withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier,
          for: annotation
        )
      }

      // Restaurant annotation
      if annotation is RestaurantAnnotation {
        return mapView.dequeueReusableAnnotationView(
          withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier,
          for: annotation
        )
      }

      return nil
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
      if view is ClusterAnnotationView,
        let clusterAnnotation = view.annotation as? MKClusterAnnotation
      {
        // Zoom in when cluster is tapped
        let currentSpan = mapView.region.span
        let memberCount = clusterAnnotation.memberAnnotations.count

        // More aggressive zoom for smaller clusters to ensure they expand
        let zoomFactor: Double
        if memberCount <= 3 {
          // Very aggressive zoom for small clusters (2-3 items)
          zoomFactor = 4.0
        } else if memberCount <= 5 {
          // Aggressive zoom for medium-small clusters (4-5 items)
          zoomFactor = 3.0
        } else {
          // Standard zoom for larger clusters
          zoomFactor = 2.0
        }

        let zoomSpan = MKCoordinateSpan(
          latitudeDelta: currentSpan.latitudeDelta / zoomFactor,
          longitudeDelta: currentSpan.longitudeDelta / zoomFactor
        )

        // Ensure minimum span to prevent over-zooming while still breaking clusters
        let minSpan = 0.001  // Approximately 100 meters
        let finalSpan = MKCoordinateSpan(
          latitudeDelta: max(zoomSpan.latitudeDelta, minSpan),
          longitudeDelta: max(zoomSpan.longitudeDelta, minSpan)
        )

        let zoomCoordinate = clusterAnnotation.coordinate
        let zoomed = MKCoordinateRegion(center: zoomCoordinate, span: finalSpan)
        mapView.setRegion(zoomed, animated: true)
      } else if let restaurantAnnotation = view.annotation as? RestaurantAnnotation {
        // Handle restaurant selection
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        parent.onRestaurantSelected(restaurantAnnotation.restaurant)
        mapView.deselectAnnotation(restaurantAnnotation, animated: false)
      }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
      // Region changes are handled internally by the map view
    }
  }
}

final class ClusterAnnotationView: MKAnnotationView {
  override var annotation: MKAnnotation? {
    didSet {
      guard let cluster = annotation as? MKClusterAnnotation else { return }
      displayPriority = .defaultHigh

      let rect = CGRect(x: 0, y: 0, width: 40, height: 40)
      image = UIGraphicsImageRenderer.clusterImage(for: cluster.memberAnnotations, in: rect)
    }
  }

  override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    collisionMode = .circle
    centerOffset = CGPoint(x: 0, y: -10)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class RestaurantAnnotationView: MKAnnotationView {
  private var imageLoadTask: URLSessionDataTask?

  override var annotation: MKAnnotation? {
    didSet {
      guard let restaurantAnnotation = annotation as? RestaurantAnnotation else { return }

      clusteringIdentifier = "Restaurant"
      displayPriority = .defaultHigh

      // Cancel any existing image load
      imageLoadTask?.cancel()

      // Set placeholder image first
      let placeholderImage = UIImage.annotationImage(
        doorImage: nil,
        rating: restaurantAnnotation.rating
      )
      image = placeholderImage

      // Load door image asynchronously
      let restaurant = restaurantAnnotation.restaurant
      let rating = restaurantAnnotation.rating

      // Get door image URL (prefer doorImage, fallback to first image)
      let imageURLString = restaurant.doorImage ?? restaurant.images.first

      if let imageURLString = imageURLString, let url = URL(string: imageURLString) {
        imageLoadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
          guard let self = self,
            let data = data,
            let doorImage = UIImage(data: data)
          else {
            return
          }

          // Generate annotation image with door image and border
          let annotationImage = UIImage.annotationImage(
            doorImage: doorImage,
            rating: rating
          )

          DispatchQueue.main.async {
            // Only update if this annotation is still the current one
            if self.annotation === restaurantAnnotation {
              self.image = annotationImage
            }
          }
        }
        imageLoadTask?.resume()
      }
    }
  }

  override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
    super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
    frame = CGRect(x: 0, y: 0, width: 40, height: 40)
    centerOffset = CGPoint(x: 0, y: -20)
    canShowCallout = false
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageLoadTask?.cancel()
    imageLoadTask = nil
  }
}

final class RestaurantAnnotation: NSObject, MKAnnotation {
  let restaurant: RestaurantModel
  let rating: RestaurantRating
  var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)
  }
  var title: String? {
    restaurant.name
  }

  init(restaurant: RestaurantModel, rating: RestaurantRating) {
    self.restaurant = restaurant
    self.rating = rating
    super.init()
  }
}
