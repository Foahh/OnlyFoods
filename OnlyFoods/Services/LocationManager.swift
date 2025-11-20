//
//  LocationManager.swift
//  AdvancedMap
//
//  Created by MJIMI_TK8 on 5/11/2025.
//

import Foundation
import CoreLocation
import MapKit

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
	
	private let locationManager = CLLocationManager()
	var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 22.28305, longitude: 114.13546), latitudinalMeters: 300, longitudinalMeters: 300)
	
	override init() {
		super.init()
		locationManager.delegate = self
		locationManager.requestWhenInUseAuthorization()
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let last = locations.last else { return }
		region.center = last.coordinate
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		if locationManager.authorizationStatus == .authorizedAlways ||  locationManager.authorizationStatus == .authorizedWhenInUse {
			locationManager.startUpdatingLocation()
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print(error)
	}
}

