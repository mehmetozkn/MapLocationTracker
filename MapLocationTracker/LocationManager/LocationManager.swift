//
//  LocationManager.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 12.05.2025.
//

import Foundation
import CoreLocation
import MapKit

protocol UserLocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager { get }
    var locationListener: ((UserLocation) -> Void)? { get }
    
    func start(desiredAccuracy: CLLocationAccuracy, locationListener: @escaping (UserLocation) -> Void)
    func stop()
}

class LocationManager: NSObject, UserLocationManager {
    var locationManager = CLLocationManager()
    var locationListener: ((UserLocation) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = 100
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    func start(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest,
               locationListener: @escaping (UserLocation) -> Void) {
        locationManager.desiredAccuracy = desiredAccuracy
        self.locationListener = locationListener
        requestLocationPermission()
        locationManager.startUpdatingLocation()
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let userLocation = UserLocation(latitude: location.coordinate.latitude,
                                        longitude: location.coordinate.longitude)
        print("📍 Konum güncellendi (arka plan olabilir): \(location.coordinate.latitude), \(location.coordinate.longitude)")
        locationListener?(userLocation)
    }

    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    deinit {
        stop()
    }
}

struct UserLocation: Encodable {
    let latitude: Double
    let longitude: Double
}
