//
//  MapViewModel.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 12.05.2025.
//

import CoreLocation
import Foundation
import MapKit

class MapViewModel {
    let locationManager: LocationServiceProtocol
    var permissionStatusDidUpdate: ((PermissionStatus) -> Void)?
    var destinationPin: MKPointAnnotation?
    var userMarkers: [MKPointAnnotation] = []
    var currentUserLocation: UserLocation?

    init(locationManager: LocationServiceProtocol = LocationManager()) {
        self.locationManager = locationManager
        locationManager.setStatusListener { [weak self] status in
            guard let self = self else { return }
            permissionStatusDidUpdate?(status)
            print("🟢 Status has changed: \(status)")
        }
    }

    func startTrackingLocation() {
        locationManager.start(desiredAccuracy: kCLLocationAccuracyBest)
    }

    func stopTrackingLocation() {
        locationManager.stop()
    }

    func toggleLocationPermission() {
        locationManager.toggleLocationPermission()
    }
}
