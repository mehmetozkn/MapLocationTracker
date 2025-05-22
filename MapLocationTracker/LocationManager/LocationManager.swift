//
//  LocationManager.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 12.05.2025.
//

import CoreLocation
import Foundation
import MapKit
import RxSwift
import RxRelay

protocol LocationServiceProtocol: CLLocationManagerDelegate {
    var userLocation: Observable<UserLocation> { get }
    var currentStatus: Observable<PermissionStatus> { get }

    func start(desiredAccuracy: CLLocationAccuracy)
    func stop()
    func changeLocationPermission()
}

final class LocationManager: NSObject, LocationServiceProtocol {
    private let locationManager = CLLocationManager()
    
    private let currentStatusRelay = BehaviorRelay<PermissionStatus>(value: .denied)
    private let userLocationRelay = PublishRelay<UserLocation>()
    
    var userLocation: Observable<UserLocation> {
        return userLocationRelay.asObservable()
    }

    var currentStatus: Observable<PermissionStatus> {
        return currentStatusRelay.asObservable()
    }

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
        let userLocation = UserLocation(from: location.coordinate)
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        userLocationRelay.accept(userLocation)
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
            currentStatusRelay.accept(.notDetermined)
        case .denied:
            currentStatusRelay.accept(.denied)
        case .authorizedAlways, .authorizedWhenInUse:
            currentStatusRelay.accept(.authorized)
        default:
            currentStatusRelay.accept(.denied)
        }
    }

    func changeLocationPermission() {
        switch currentStatusRelay.value {
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
