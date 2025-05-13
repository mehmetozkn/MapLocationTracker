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

    init(locationManager: LocationServiceProtocol = LocationManager()) {
        self.locationManager = locationManager
        locationManager.setStatusListener { [weak self] status in
            self?.permissionStatusDidUpdate?(status)
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
