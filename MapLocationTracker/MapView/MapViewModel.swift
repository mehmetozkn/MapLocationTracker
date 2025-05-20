//
//  MapViewModel.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 12.05.2025.
//

import CoreLocation
import Foundation
import MapKit

final class MapViewModel {
    private let locationManager: LocationServiceProtocol
    var destinationPin: MKPointAnnotation?
    var currentUserLocation: UserLocation?

    init(locationManager: LocationServiceProtocol = LocationManager()) {
        self.locationManager = locationManager
    }

    func startTrackingLocation() {
        locationManager.start(desiredAccuracy: kCLLocationAccuracyBest)
    }

    func stopTrackingLocation() {
        locationManager.stop()
    }

    func toggleLocationPermission() {
        locationManager.changeLocationPermission()
    }
}
