//
//  ViewController.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 12.05.2025.
//x

import MapKit
import UIKit

class MapViewController: UIViewController {
    private var viewModel = MapViewModel()
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationPermission: UIButton! {
        didSet {
            locationPermission.addTarget(
                self, action: #selector(toggleLocationPermission),
                for: .touchUpInside)
        }
    }

    @IBOutlet weak var resetRoute: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        viewModel.startTrackingLocation()
        NotificationCenter.default.addObserver(
            self, selector: #selector(didUpdateUserLocation(_:)),
            name: .didUpdateUserLocation, object: nil)
        viewModel.permissionStatusDidUpdate = { [weak self] status in
            self?.updatePermissionButton(with: status)
        }
    }

    @objc private func toggleLocationPermission() {
        viewModel.toggleLocationPermission()
    }

    deinit {
        viewModel.stopTrackingLocation()
        NotificationCenter.default.removeObserver(
            self, name: .didUpdateUserLocation, object: nil)
    }

    @objc private func didUpdateUserLocation(_ notification: Notification) {
        guard let userLocation = notification.object as? UserLocation else {
            return
        }
        addMarker(at: userLocation)
    }

    private func addMarker(at userLocation: UserLocation) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude)
        mapView.addAnnotation(annotation)
        let region = MKCoordinateRegion(
            center: annotation.coordinate,
            latitudinalMeters: 600,
            longitudinalMeters: 600)
        mapView.setRegion(region, animated: true)
    }
    private func updatePermissionButton(with status: PermissionStatus) {
        let title =
            status == .authorized
            ? "Location is on. Click to close."
            : "Location is off. Click to on."
        locationPermission.setTitle(title, for: .normal)
        let titleColor: UIColor =
            status == .authorized ? .systemGreen : .systemRed
        locationPermission.setTitleColor(titleColor, for: .normal)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        let coordinate = annotation.coordinate

        let geocoder = CLGeocoder()
        let location = CLLocation(
            latitude: coordinate.latitude, longitude: coordinate.longitude)

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

    private func showAddressAlert(address: String) {
        let alert = UIAlertController(
            title: "Adres", message: address, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "Tamam", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
