//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Srikar Thottempudi on 5/19/19.
//  Copyright © 2019 Srikar Thottempudi. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var travelLocationDataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var coordinate: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        mapView.isUserInteractionEnabled = true // To detect the user events.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setUpFetchedResultsController()
        loadMap() // Checks if the user previously zoomed in on any location, if so load that location.
        reloadMap()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: Called when user long presses on the map
    @IBAction func annotateLocation(_ gestureRecognizer: UILongPressGestureRecognizer) {
        //print("long press is recognized")
        
        let cgPoint = gestureRecognizer.location(in: mapView)
        let coordinates = mapView.convert(cgPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        
        coordinate = coordinates
        
        // Add an annotation as soon as the long press is ended
        if gestureRecognizer.state == .ended {
            mapView.addAnnotation(annotation)
            persistPin(pinCoordinate: coordinate)
        }
    }
    
    // MARK: Setting up the fetched results controller
    private func setUpFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: travelLocationDataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("TravelLocationsVC: Unable to fetch the results")
        }
    }
    
    private func loadMap() {
        if UserDefaults.standard.value(forKey: "loggedLocation") != nil { // To detect the first launch as nothing is stored.
            let latitude = UserDefaults.standard.double(forKey: "lastLatitude")
            let longitude = UserDefaults.standard.double(forKey: "lastLongitude")
            let latitudeSpan = UserDefaults.standard.double(forKey: "lastLatitudeSpan")
            let longitudeSpan = UserDefaults.standard.double(forKey: "lastLongitudeSpan")
            let lastLoggedLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            mapView.region = MKCoordinateRegion(center: lastLoggedLocation, span: MKCoordinateSpan(latitudeDelta: latitudeSpan, longitudeDelta: longitudeSpan))
        } else {
            UserDefaults.standard.setValue(true, forKey: "loggedLocation")
        }
    }
    
    // MARK: Storing the coordinates user dropped pin on
    private func persistPin(pinCoordinate: CLLocationCoordinate2D) {
        // Associating the pin with context
        let pin = Pin(context: travelLocationDataController.viewContext)
        
        // Storing latitude and longitude
        pin.latitude = pinCoordinate.latitude
        pin.longitude = pinCoordinate.longitude
        pin.creationDate = Date()
        
        do {
            try travelLocationDataController.viewContext.save()
        } catch {
            fatalError("Unable to save the data")
        }
    }
}

extension TravelLocationsViewController: MKMapViewDelegate {
    
    // MARK: Fetch pins and add them to map view
    func reloadMap() {
        
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins {
                let pinLatitude = pin.latitude
                let pinLongitude = pin.longitude
                let pinCoordinate = CLLocationCoordinate2D(latitude: pinLatitude, longitude: pinLongitude)
                let annotation = MKPointAnnotation()
                annotation.coordinate = pinCoordinate
                DispatchQueue.main.async {
                    self.mapView.addAnnotation(annotation)
                }
            }
        }
    }
    
    // This is called when visible region of the map is changed.
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let region = mapView.region.center
        let lastLoggedLatitude = region.latitude
        let lastLoggedLongitude = region.longitude
        let latitudeSpan = mapView.region.span.latitudeDelta
        let longitudeSpan = mapView.region.span.longitudeDelta
        // Storing the area that user zoomed in using user defaults
        UserDefaults.standard.set(lastLoggedLatitude, forKey: "lastLatitude")
        UserDefaults.standard.set(lastLoggedLongitude, forKey: "lastLongitude")
        UserDefaults.standard.set(latitudeSpan, forKey: "lastLatitudeSpan")
        UserDefaults.standard.set(longitudeSpan, forKey: "lastLongitudeSpan")
        UserDefaults.standard.synchronize()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let pinReuseIdentifier = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: pinReuseIdentifier) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: pinReuseIdentifier)
            pinView?.canShowCallout = false
            pinView?.pinTintColor = .red
            pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    // Navigate to PhotoAlbum when user taps on the pin.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let clickedAnnotation = view.annotation
        let clickedAnnotationLatitude = clickedAnnotation?.coordinate.latitude
        let clickedAnnotationLongitude = clickedAnnotation?.coordinate.longitude
        
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins {
                if pin.latitude == clickedAnnotationLatitude && pin.longitude == clickedAnnotationLongitude {
                    let photoAlbumVC = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbum") as! PhotoAlbumViewController
                    photoAlbumVC.pin = pin
                    photoAlbumVC.photoAlbumDataController = travelLocationDataController
                    self.navigationController?.pushViewController(photoAlbumVC, animated: true)
                }
            }
        }
    }
}

extension TravelLocationsViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        guard let pin = anObject as? Pin else {
            print("Only pin instances should be persisted")
            return
        }
        
        switch type {
        case .insert:
            mapView.addAnnotation(pin)
        case .update, .delete:
            mapView.removeAnnotation(pin)
        case .move:
            print("Cannot update the pin")
        }
    }
}

