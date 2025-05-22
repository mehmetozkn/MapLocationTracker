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
    var currentUserLocation: LocationModel?
    var markers: [LocationModel] = []
    
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
    
    func showNewRoute(at coordinate: CLLocationCoordinate2D, userLocation: LocationModel?, completion: @escaping (MKRoute?) -> Void) {
        guard let userLoc = userLocation else { return }
        calculateRoute(from: CLLocationCoordinate2D(latitude: userLoc.latitude, longitude: userLoc.longitude), to: coordinate) { route in
            if route != nil {
                self.saveRoute(coordinate)
            }
            completion(route)
        }
    }
}

// MARK: - Route Save Operations

extension MapViewModel {
    func addMarkerToSave(at userLocation: LocationModel?) {
        guard let userLocation = userLocation else { return }
        markers.append(userLocation)
        saveMarkers(markers)
    }
    
    func saveMarkers(_ markers: [LocationModel]) {
        AppStorageManager.shared.save(markers, key: PersistencyKey.savedMarkers)
    }

    func getSavedMarkers() -> [LocationModel]? {
        guard let markers = AppStorageManager.shared.get(key: PersistencyKey.savedMarkers, as: [LocationModel].self) else { return nil }
        return markers
    }
    
    func saveRoute(_ coordinate: CLLocationCoordinate2D) {
        let location = LocationModel(from: coordinate)
        AppStorageManager.shared.save(location, key: PersistencyKey.savedRoute)
    }
    
    func clearSavedRoute() {
        AppStorageManager.shared.remove(forKey: PersistencyKey.savedRoute)
        AppStorageManager.shared.remove(forKey: PersistencyKey.savedMarkers)
        destinationPin = nil
        markers = []
    }
    
    func getSavedRoute() -> CLLocationCoordinate2D? {
        guard let location = AppStorageManager.shared.get(key: PersistencyKey.savedRoute, as: LocationModel.self) else { return nil }
        return location.asCLLocationCoordinate2D
    }
}

