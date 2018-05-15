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
        currentCoordinates = getPosition().Location
        currentAltitude = getPosition().Altitude
        ARView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        configuration.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading
        ARView.session.run(configuration)
        if let curCoord = currentCoordinates {
            print(Constants.osrmUrl(origin: curCoord, goal: destinationCoordinates))
            jsonFetcher.fetchJSON(fromURL: Constants.osrmUrl(origin: curCoord, goal: destinationCoordinates)) { jsonData, _ in
                if let routeData = jsonData {
                    let route = Route(json: routeData)
                    print(routeData)
                }
            }
        }
        
        // TO-DO: Fix with guard let
    }
    
    func getPosition() -> (Location: CLLocationCoordinate2D, Altitude: Double) {
        let curCoordinates = CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        let altitude = (locationManager.location?.altitude)!
        return (curCoordinates, altitude)
    }
    
    func getDistance(currentLocation: CLLocationCoordinate2D, destinationLocation: CLLocationCoordinate2D) -> (lat: Double, long: Double) {
        var distance: (lat: Double, long: Double)
        distance.long = destinationLocation.DistanceTo(latitudeTo: destinationLocation.latitude, longitudeTo: currentLocation.longitude)
        distance.lat = destinationLocation.DistanceTo(latitudeTo: currentLocation.latitude, longitudeTo: destinationLocation.longitude)
        print(distance.lat, distance.long)
        return distance
    }
    
    func altitudeDiff(currentAltitude: Double, destAltitude: Double) -> Double {
        return destAltitude - currentAltitude
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func add(_ sender: Any) {
        addNodeToScene(destinationLoc: destinationCoordinates, destinationAltitude: testAltitude)
    }
    
    func addNodeToScene(destinationLoc: CLLocationCoordinate2D, destinationAltitude: Double) {
        let node = SCNNode()
        node.geometry = SCNBox(width: 1, height: 0.5, length: 1, chamferRadius: 0)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        if let cLoc = currentCoordinates {
            var distance = getDistance(currentLocation: cLoc, destinationLocation: destinationCoordinates)
            if destinationLoc.latitude > cLoc.latitude {
                distance.lat = -distance.lat
            }
            if destinationLoc.longitude < cLoc.longitude{
                distance.long = -distance.long
            }
            if let currAltitude = currentAltitude{
                let altitude = altitudeDiff(currentAltitude: currAltitude, destAltitude: testAltitude)
                node.position = SCNVector3(distance.long, altitude, distance.lat)
            }
        }
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
