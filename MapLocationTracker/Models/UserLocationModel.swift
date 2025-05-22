//
//  UserLocationModel.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 20.05.2025.
//

import CoreLocation

struct UserLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    
    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    var asCLLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
