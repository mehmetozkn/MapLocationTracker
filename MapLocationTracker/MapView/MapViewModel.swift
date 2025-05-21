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

    func changeLocationPermission() {
        locationManager.changeLocationPermission()
    }
    
    func saveRoute(_ coordinate: CLLocationCoordinate2D) {
        let data: [String: Double] = ["lat": coordinate.latitude, "lng": coordinate.longitude]
        AppStorageManager.shared.save(data: data, forKey: PersistencyKey.savedRoute)
    }
    
    func calculateRoute(from source: CLLocationCoordinate2D,
                        to destination: CLLocationCoordinate2D,
                        completion: @escaping (MKRoute?) -> Void) {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)
        directions.calculate { response, error in
            if let error = error {
                print("🔴 Failed to calculate route:", error.localizedDescription)
                completion(nil)
            } else {
                completion(response?.routes.first)
            }
        }
    }
    
    func getSavedRoute() -> CLLocationCoordinate2D? {
        guard let saved = AppStorageManager.shared.get(forKey: PersistencyKey.savedRoute) as? [String: Double],
              let lat = saved["lat"],
              let lng = saved["lng"] else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}
