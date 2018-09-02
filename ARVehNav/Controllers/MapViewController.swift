//
//  MapViewController.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 04/05/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import UIKit
import MapKit

protocol handleMapSearch{
    func dropPinZoom(place: MKPlacemark)
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var destinationMapView: MKMapView!
    @IBOutlet weak var toolBar: UIToolbar!
    
    private var resultSearchController:UISearchController? = nil
    private var selectedPin: MKPlacemark? = nil
    private var headingTimer: Timer!
    

    internal var mapLocation: CLLocationCoordinate2D?

    override func viewDidLoad() {
        super.viewDidLoad()
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleTap(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 0.5
        gestureRecognizer.delaysTouchesBegan = true

        destinationMapView.delegate = self
        destinationMapView.showsScale = true
        destinationMapView.showsCompass = true
        destinationMapView.showsUserLocation = true
        destinationMapView.setUserTrackingMode(.followWithHeading, animated: true)
        gestureRecognizer.delegate = self as? UIGestureRecognizerDelegate
        destinationMapView.addGestureRecognizer(gestureRecognizer)
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = NSLocalizedString("searchPlaces", comment: "Search for places")
        navigationItem.titleView = resultSearchController?.searchBar
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchTable.destinationMapView = destinationMapView
        locationSearchTable.handleMapSearchDelegate = self
        
        print(destinationMapView.camera.heading)
        
//        if let loc = LocationManager.shared.lastLocation{
//            let center = CLLocationCoordinate2D(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude)
//            let regio = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
//            self.destinationMapView.setRegion(regio, animated: true)
//        }
    }
    
    func setMapLocation(coord: CLLocationCoordinate2D){
        mapLocation = coord
    }

    @objc func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.began { return }
        let touchLocation = gestureRecognizer.location(in: destinationMapView)
        let locationCoordinate = destinationMapView.convert(touchLocation, toCoordinateFrom: destinationMapView)
        mapLocation = locationCoordinate
        let mapAnnotations = destinationMapView.annotations
        destinationMapView.removeAnnotations(mapAnnotations)
        let pinPoint = MKPointAnnotation()
        pinPoint.coordinate = locationCoordinate
        destinationMapView.addAnnotation(pinPoint)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowARViewSegue" {
            if let destinationVC = segue.destination as? ARViewController {
                if let coordinates = mapLocation {
                    destinationVC.destinationCoordinates = coordinates
                }
            }
        }
    }
}

extension MapViewController:handleMapSearch{
    func dropPinZoom(place: MKPlacemark) {
        selectedPin = place
        destinationMapView.removeAnnotations(destinationMapView.annotations)
        let selectedPlace = MKPointAnnotation()
        selectedPlace.coordinate = place.coordinate
        selectedPlace.title = place.name
        if let city = place.locality{
            selectedPlace.subtitle = city
        }
        setMapLocation(coord: place.coordinate)
        destinationMapView.addAnnotation(selectedPlace)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(selectedPlace.coordinate, span)
        destinationMapView.setRegion(region, animated: true)
    }
}
