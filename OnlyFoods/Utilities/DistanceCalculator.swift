//
//  DistanceCalculator.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/21.
//

import CoreLocation
import Foundation

struct DistanceCalculator {
  /// Calculate distance in meters between two coordinates
  static func distance(
    from coordinate1: CLLocationCoordinate2D,
    to coordinate2: CLLocationCoordinate2D
  ) -> Double {
    let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
    let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
    return location1.distance(from: location2)
  }

  /// Calculate distance in meters from a location to a coordinate
  static func distance(from location: CLLocation, to coordinate: CLLocationCoordinate2D) -> Double {
    let targetLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    return location.distance(from: targetLocation)
  }

  /// Format distance in a human-readable string
  static func formatDistance(_ distanceInMeters: Double) -> String {
    if distanceInMeters < 1000 {
      return String(format: "%.0f m", distanceInMeters)
    } else {
      let kilometers = distanceInMeters / 1000
      return String(format: "%.1f km", kilometers)
    }
  }
}
