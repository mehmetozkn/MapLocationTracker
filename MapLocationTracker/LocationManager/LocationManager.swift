//
//  LocationManager.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 12.05.2025.
//

import CoreLocation
import Foundation
import MapKit
import Combine

protocol LocationServiceProtocol: CLLocationManagerDelegate {
    func start(desiredAccuracy: CLLocationAccuracy)
    func stop()
    func changeLocationPermission()
}

final class LocationManager: NSObject, LocationServiceProtocol {
    private let locationManager = CLLocationManager()
    
    @Published var currentStatus: PermissionStatus = .denied
    @Published var userLocation: LocationModel?

    override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.distanceFilter = 100
        locationManager.allowsBackgroundLocationUpdates = true
    }

    func start(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest) {
        locationManager.desiredAccuracy = desiredAccuracy
        requestLocationPermission()
        locationManager.startUpdatingLocation()
    }

    func stop() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let userLocation = LocationModel(from: location.coordinate)
        self.userLocation = userLocation
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }

    private func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    deinit {
        stop()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            self.currentStatus = .notDetermined
        case .denied:
            self.currentStatus = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            self.currentStatus = .authorized
        default:
            self.currentStatus = .denied
        }
    }

    func changeLocationPermission() {
        switch currentStatus {
        case .notDetermined:
            requestLocationPermission()
        default:
            openAppSettings()
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString)
        else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
}
