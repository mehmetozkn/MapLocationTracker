//
//  MapViewModel.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 12.05.2025.
//

import Foundation
import CoreLocation
import MapKit

class MapViewModel {
    var locationManager: LocationManager
    var didUpdateLocation: ((UserLocation) -> Void)?

    init() {
        self.locationManager = LocationManager()
    }

    func startTrackingLocation() {
        locationManager.start { [weak self] userLocation in
            self?.didUpdateLocation?(userLocation)
        }
    }

    func stopTrackingLocation() {
        locationManager.stop()
    }
}

