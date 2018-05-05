//
//  ARViewController.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 26/02/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation

class ARViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    var destinationCoordinates = CLLocationCoordinate2D(latitude: 45.31262084016531, longitude: 18.406627540010845)
    var testAltitude = 102.0
    var currentCoordinates: CLLocationCoordinate2D?
    private var currentAltitude: Double?
    var distanceLat: Double = 0
    var distanceLong: Double = 0
    var degreesCompass: Double = 0
    
    private let jsonFetcher = NFetcher()
    
    @IBOutlet weak var ARView: ARSCNView!
    @IBOutlet weak var GPSLoc: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
            locationManager.delegate = self
        }
        
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
            locationManager.delegate = self
        }
        getPosition()
        ARView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        configuration.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading
        ARView.session.run(configuration)
        if let curCoord = currentCoordinates {
            print(Constants.osrmUrl(origin: curCoord, goal: destinationCoordinates))
            jsonFetcher.fetchJSON(fromURL: Constants.osrmUrl(origin: curCoord, goal: destinationCoordinates)) { jsonData, _ in
                if let routeData = jsonData {
                    let route = Route(json: routeData)
                    print(route!)
                }
            }
        }
        getDistance()
        // TO-DO: Fix with guard let
    }
    
    func getPosition() {
        currentCoordinates = CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        currentAltitude = (locationManager.location?.altitude)!
    }
    
    func getDistance() {
        if let nowCoordinates = currentCoordinates {
            distanceLat = destinationCoordinates.DistanceTo(latitudeTo: destinationCoordinates.latitude, longitudeTo: nowCoordinates.longitude)
            distanceLong = destinationCoordinates.DistanceTo(latitudeTo: nowCoordinates.latitude, longitudeTo: destinationCoordinates.longitude)
            print(distanceLat, distanceLong)
        }
        if let cAltitude = currentAltitude {
            testAltitude = cAltitude - testAltitude
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func add(_ sender: Any) {
        let node = SCNNode()
        node.geometry = SCNBox(width: 1, height: 0.5, length: 1, chamferRadius: 0)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        node.position = SCNVector3(distanceLat, 0, -distanceLong)
        ARView.scene.rootNode.addChildNode(node)
    }
    
    @IBAction func reset(_ sender: Any) {
        restartSession()
    }
    
    func restartSession() {
        ARView.session.pause()
        ARView.scene.rootNode.enumerateChildNodes { node, _ in
            node.removeFromParentNode()
        }
        ARView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        getPosition()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        degreesCompass = newHeading.magneticHeading
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        DispatchQueue.main.async {
            self.GPSLoc?.text = "\(locValue.latitude) \(locValue.longitude)"
        }
    }
    
    func loadRouteData(url: URL) {
        
    }
}
