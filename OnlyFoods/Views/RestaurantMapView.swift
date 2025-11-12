//
//  RestaurantMapView.swift
//  OnlyFoods
//
//  Created by Foahh on 2025/11/12.
//

import MapKit
import SwiftUI

struct RestaurantMapView: View {
  let latitude: Double
  let longitude: Double
  let restaurantName: String

  @State private var region: MKCoordinateRegion

  init(latitude: Double, longitude: Double, restaurantName: String) {
    self.latitude = latitude
    self.longitude = longitude
    self.restaurantName = restaurantName
    _region = State(
      initialValue: MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
      ))
  }

  var body: some View {
    Map(
      coordinateRegion: $region,
      annotationItems: [
        RestaurantAnnotation(
          coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
          title: restaurantName
        )
      ]
    ) { annotation in
      MapPin(coordinate: annotation.coordinate, tint: .red)
    }
    .onTapGesture {
      // Open in Maps app
      let mapItem = MKMapItem(
        placemark: MKPlacemark(
          coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        ))
      mapItem.name = restaurantName
      mapItem.openInMaps()
    }
  }
}

struct RestaurantAnnotation: Identifiable {
  let id = UUID()
  let coordinate: CLLocationCoordinate2D
  let title: String
}

#Preview {
  RestaurantMapView(
    latitude: 22.3193,
    longitude: 114.1694,
    restaurantName: "Sample Restaurant"
  )
  .frame(height: 200)
}
