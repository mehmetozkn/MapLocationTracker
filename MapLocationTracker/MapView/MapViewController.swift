//
//  ViewController.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 12.05.2025.
//

import UIKit
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate {

    private var viewModel = MapViewModel()
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationPermission: UIButton!
    @IBOutlet weak var resetRoute: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        viewModel.startTrackingLocation()
        viewModel.didUpdateLocation = { [weak self] userLocation in
            self?.addMarker(at: userLocation)
        }
    }

    deinit {
        viewModel.stopTrackingLocation()
    }

    func addMarker(at userLocation: UserLocation) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: userLocation.latitude,
                                                       longitude: userLocation.longitude)
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(center: annotation.coordinate,
                                        latitudinalMeters: 600,
                                        longitudinalMeters: 600)
        mapView.setRegion(region, animated: true)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        let coordinate = annotation.coordinate
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Hata: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                let address = """
                \(placemark.name ?? "")
                \(placemark.locality ?? "")
                \(placemark.administrativeArea ?? "")
                \(placemark.country ?? "")
                """
                
                self.showAddressAlert(address: address)
            }
        }
        mapView.deselectAnnotation(annotation, animated: true)
    }
    
    func showAddressAlert(address: String) {
        let alert = UIAlertController(title: "Adres", message: address, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

