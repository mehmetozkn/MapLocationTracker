//
//  MapViewController.swift
//  MapLocationTracker
//
//  Created by Mehmet Özkan on 12.05.2025.
//

import MapKit
import UIKit

final class MapViewController: UIViewController {
    private let viewModel = MapViewModel()

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            let longPressGesture = UILongPressGestureRecognizer(
                target: self, action: #selector(handleLongPress(_:)))
            mapView.addGestureRecognizer(longPressGesture)
        }
    }

    @IBOutlet weak var locationPermission: UIButton! {
        didSet {
            locationPermission.addTarget(self, action: #selector(changeLocationPermission), for: .touchUpInside)
        }
    }

    @IBOutlet weak var resetRoute: UIButton! {
        didSet {
            resetRoute.addTarget(self, action: #selector(clearRoute), for: .touchUpInside)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        viewModel.startTrackingLocation()
    }

    deinit {
        cleanUp()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didUpdateUserLocation(_:)),
            name: .userLocation,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didUpdateLocationStatus(_:)),
            name: .locationStatus,
            object: nil)
    }

    private func cleanUp() {
        viewModel.stopTrackingLocation()
        NotificationCenter.default.removeObserver(
            self, name: .userLocation, object: nil)
        NotificationCenter.default.removeObserver(
            self, name: .locationStatus, object: nil)
    }

    private func setupUI() {
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
}

// MARK: - Map Operations

extension MapViewController {
    private func saveDestinationAndDrawRoute(from userLocation: UserLocation, to destination: CLLocationCoordinate2D) {
        let fromCoordinate = CLLocationCoordinate2D(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude)

        drawRoute(from: fromCoordinate, to: destination)
        addDestinationPin(at: destination)
        viewModel.saveRoute(destination)
    }

    private func drawRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        viewModel.calculateRoute(from: source, to: destination) { [weak self] route in
            guard let self = self, let route = route else { return }

            self.mapView.removeOverlays(self.mapView.overlays)
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                           edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60),
                                           animated: true
            )
        }
    }

    private func addDestinationPin(at coordinate: CLLocationCoordinate2D) {
        if let oldPin = viewModel.destinationPin {
            mapView.removeAnnotation(oldPin)
        }

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Destination"

        mapView.addAnnotation(annotation)

        viewModel.destinationPin = annotation
    }

    private func addMarker(at userLocation: UserLocation?) {
        guard let userLocation else { return }
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: userLocation.latitude,longitude: userLocation.longitude)
        mapView.addAnnotation(annotation)
    }

    private func zoomMap(annotation: MKPointAnnotation) {
        let region = MKCoordinateRegion(center: annotation.coordinate,
                                        latitudinalMeters: 900,
                                        longitudinalMeters: 900)
        mapView.setRegion(region, animated: true)
    }

    private func showAddressAlert(address: String) {
        let alert = UIAlertController(title: "Address", message: address, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - Objc Methods

extension MapViewController {
    @objc func didUpdateUserLocation(_ notification: Notification) {
        guard let userLocation = notification.object as? UserLocation else {
            return
        }

        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: userLocation.latitude,longitude: userLocation.longitude)

        zoomMap(annotation: annotation)

        if let locationMarker = viewModel.currentUserLocation {
            addMarker(at: locationMarker)
        }

        viewModel.currentUserLocation = userLocation
        
        if let savedRoute = viewModel.getSavedRoute() {
            saveDestinationAndDrawRoute(from: userLocation, to: savedRoute)
        }
    }

    @objc func didUpdateLocationStatus(_ notification: Notification) {
        guard let status = notification.object as? PermissionStatus else {
            return
        }
        let title = status == .authorized ? "Location is on. Click to close." : "Location is off. Click to on."
        locationPermission.setTitle(title, for: .normal)
        let titleColor: UIColor = status == .authorized ? .systemGreen : .systemRed
        locationPermission.setTitleColor(titleColor, for: .normal)
    }

    @objc func changeLocationPermission() {
        viewModel.changeLocationPermission()
    }

    @objc func clearRoute() {
        mapView.removeOverlays(mapView.overlays)
        
        if let oldPin = viewModel.destinationPin {
            mapView.removeAnnotation(oldPin)
        }
        viewModel.clearSavedRoute()
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let locationInView = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)

            let alert = UIAlertController(title: "Route", message: "Plot a route to this location?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                guard let self = self, let userLoc = self.viewModel.currentUserLocation else { return }
                self.viewModel.showNewRoute(at: coordinate, userLocation: userLoc) { route in
                    DispatchQueue.main.async {
                        if let route = route {
                            self.mapView.removeOverlays(self.mapView.overlays)
                            self.mapView.addOverlay(route.polyline)
                            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60), animated: true)
                        }
                        self.addDestinationPin(at: coordinate)
                    }
                }
            }))
            present(alert, animated: true)
        }
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer{
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer()
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        if let pointAnnotation = annotation as? MKPointAnnotation {
            if pointAnnotation.title == "Destination" {
                let identifier = "GreenPin"
                var annotationView = mapView.dequeueReusableAnnotationView(
                    withIdentifier: identifier)
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(
                        annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                }
                if let markerView = annotationView as? MKMarkerAnnotationView {
                    markerView.markerTintColor = .green
                    markerView.glyphImage = UIImage(
                        systemName: "mappin.and.ellipse")
                }
                return annotationView
            } else {
                let identifier = "UserPin"
                var annotationView = mapView.dequeueReusableAnnotationView(
                    withIdentifier: identifier)
                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(
                        annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                }
                if let markerView = annotationView as? MKMarkerAnnotationView {
                    markerView.markerTintColor = .red
                }
                return annotationView
            }
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        let coordinate = annotation.coordinate

        let geocoder = CLGeocoder()
        let location = CLLocation(
            latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
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
}
