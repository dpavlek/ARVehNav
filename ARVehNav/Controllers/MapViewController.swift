//
//  MapViewController.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 04/05/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var destinationMapView: MKMapView!

    internal var mapLocation: (lat: Double, long: Double)?

    override func viewDidLoad() {
        super.viewDidLoad()
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.handleTap(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 1.0
        gestureRecognizer.delaysTouchesBegan = true

        destinationMapView.delegate = self
        title = "Set Destination"
        gestureRecognizer.delegate = self as? UIGestureRecognizerDelegate
        destinationMapView.addGestureRecognizer(gestureRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func handleTap(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.began { return }
        let touchLocation = gestureRecognizer.location(in: destinationMapView)
        let locationCoordinate = destinationMapView.convert(touchLocation, toCoordinateFrom: destinationMapView)
        mapLocation = (lat: locationCoordinate.latitude, long: locationCoordinate.longitude)
        let mapAnnotations = destinationMapView.annotations
        destinationMapView.removeAnnotations(mapAnnotations)
        let pinPoint = MKPointAnnotation()
        pinPoint.coordinate = CLLocationCoordinate2D(latitude: locationCoordinate.latitude, longitude: locationCoordinate.longitude)
        destinationMapView.addAnnotation(pinPoint)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowARViewSegue" {
            if let destinationVC = segue.destination as? ARViewController {
                if let latitude = mapLocation?.lat {
                    destinationVC.destinationCoordinates.latitude = latitude
                }
                if let longitude = mapLocation?.long {
                    destinationVC.destinationCoordinates.longitude = longitude
                }
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
