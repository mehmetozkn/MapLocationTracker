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
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            mapView.addGestureRecognizer(longPressGesture)
        }
    }
    @IBOutlet weak var locationPermission: UIButton! {
        didSet {
            locationPermission.addTarget(
                self, action: #selector(toggleLocationPermission), for: .touchUpInside)
        }
    }

    @IBOutlet weak var resetRoute: UIButton! {
        didSet {
            resetRoute.addTarget(self, action: #selector(clearRoute), for: .touchUpInside)
        }
    }
    var destinationPin: MKPointAnnotation?

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        viewModel.startTrackingLocation()
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateUserLocation(_:)), name: .didUpdateUserLocation, object: nil)
        viewModel.permissionStatusDidUpdate = { [weak self] status in
            self?.updatePermissionButton(with: status)
        }
    }
    
    deinit {
        viewModel.stopTrackingLocation()
        NotificationCenter.default.removeObserver(
            self, name: .didUpdateUserLocation, object: nil)
    }
    
    private func saveDestinationAndDrawRoute(from userLocation: UserLocation, to destination: CLLocationCoordinate2D) {
        let fromCoordinate = CLLocationCoordinate2D(latitude: userLocation.latitude,
                                                    longitude: userLocation.longitude)

        drawRoute(from: fromCoordinate, to: destination)
        addDestinationPin(at: destination)

        let data: [String: Double] = ["lat": destination.latitude, "lng": destination.longitude]
        UserDefaults.standard.setValue(data, forKey: PersistencyKey.savedRouteDestination)
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
    
    private func drawRoute(from source: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        let sourcePlacemark = MKPlacemark(coordinate: source)
        let destinationPlacemark = MKPlacemark(coordinate: destination)

        let directionRequest = MKDirections.Request()
        directionRequest.source = MKMapItem(placemark: sourcePlacemark)
        directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionRequest.transportType = .automobile

        let directions = MKDirections(request: directionRequest)
        directions.calculate { [weak self] response, error in
            guard let route = response?.routes.first else {
                print("The route could not be drawn:", error?.localizedDescription ?? "")
                return
            }

            self?.mapView.removeOverlays(self?.mapView.overlays ?? [])
            self?.mapView.addOverlay(route.polyline)

            self?.mapView.setVisibleMapRect(
                route.polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(top: 60, left: 60, bottom: 60, right: 60),
                animated: true
            )
        }
    }
    
    private func addDestinationPin(at coordinate: CLLocationCoordinate2D) {
        if let oldPin = destinationPin {
            mapView.removeAnnotation(oldPin)
        }

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "Destination"
        
        mapView.addAnnotation(annotation)

        destinationPin = annotation
    }

}

// MARK: - Objc Selectors

private extension MapViewController {
    @objc func didUpdateUserLocation(_ notification: Notification) {
        guard let userLocation = notification.object as? UserLocation else {
            return
        }
        addMarker(at: userLocation)
        if let saved = UserDefaults.standard.dictionary(forKey: PersistencyKey.savedRouteDestination) as? [String: Double],
           let lat = saved["lat"], let lng = saved["lng"] {
            let destinationCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
            
            saveDestinationAndDrawRoute(from: userLocation, to: destinationCoordinate)
        }
    }
    
    @objc func toggleLocationPermission() {
        viewModel.toggleLocationPermission()
    }
    
    @objc func clearRoute() {
        mapView.removeOverlays(mapView.overlays)
        if let oldPin = destinationPin {
            mapView.removeAnnotation(oldPin)
            destinationPin = nil
        }
        UserDefaults.standard.removeObject(forKey: PersistencyKey.savedRouteDestination)
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let locationInView = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)

            let alert = UIAlertController(title: "Rota", message: "Plot a route to this location?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                if let userLocation = self.mapView.annotations
                    .compactMap({ $0 as? MKPointAnnotation })
                    .first(where: { $0.title == nil }) {
                    let userLoc = UserLocation(latitude: userLocation.coordinate.latitude,
                                               longitude: userLocation.coordinate.longitude)
                    self.saveDestinationAndDrawRoute(from: userLoc, to: coordinate)
                } else {
                    print("📍 User location not found.")
                }
            }))
            present(alert, animated: true)
        }
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(overlay: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let pointAnnotation = annotation as? MKPointAnnotation {
            if pointAnnotation.title == "Destination" {
                let identifier = "GreenPin"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                }

                if let markerView = annotationView as? MKMarkerAnnotationView {
                    markerView.markerTintColor = .green
                    markerView.glyphImage = UIImage(systemName: "mappin.and.ellipse")
                }

                return annotationView
            }
            else {
                let identifier = "UserPin"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
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

    private func showAddressAlert(address: String) {
        let alert = UIAlertController(
            title: "Address", message: address, preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
