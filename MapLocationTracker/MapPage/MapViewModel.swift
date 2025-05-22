//
//  MapViewModel.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 12.05.2025.
//

import CoreLocation
import Foundation
import MapKit

final class MapViewModel: ObservableObject {
    private let locationManager: LocationManager
    var destinationPin: MKPointAnnotation?

    @Published var currentStatus: PermissionStatus = .denied
    @Published var userLocation: LocationModel?
    
    init(locationManager: LocationManager = LocationManager()) {
        self.locationManager = locationManager
        bind()
    }
    
    private func bind() {
        locationManager.$currentStatus
            .receive(on: RunLoop.main)
            .assign(to: &$currentStatus)
        
        locationManager.$userLocation
            .receive(on: RunLoop.main)
            .assign(to: &$userLocation)
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
        let location = LocationModel(from: coordinate)
        AppStorageManager.shared.save(location, forKey: PersistencyKey.savedRoute)
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
        guard let location: LocationModel = AppStorageManager.shared.get(forKey: PersistencyKey.savedRoute, as: LocationModel.self) else {
            return nil
        }
        return location.asCLLocationCoordinate2D
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
    
    func clearSavedRoute() {
        AppStorageManager.shared.remove(forKey: PersistencyKey.savedRoute)
        destinationPin = nil
    }
}
