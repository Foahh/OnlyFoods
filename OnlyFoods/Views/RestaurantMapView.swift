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

  @State private var cameraPosition: MapCameraPosition

  init(latitude: Double, longitude: Double, restaurantName: String) {
    self.latitude = latitude
    self.longitude = longitude
    self.restaurantName = restaurantName
    _cameraPosition = State(
      initialValue: .region(
        MKCoordinateRegion(
          center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
          span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
      )
    )
  }

  var body: some View {
    Map(position: $cameraPosition, interactionModes: []) {
      Marker(
        restaurantName,
        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
      )
      .tint(.red)
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

#Preview {
  RestaurantMapView(
    latitude: 22.3193,
    longitude: 114.1694,
    restaurantName: "Sample Restaurant"
  )
  .frame(height: 200)
}
