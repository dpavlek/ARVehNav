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
    var currentLocation: CLLocation!
    
    var testCoordinate = CLLocationCoordinate2D(latitude: 45.31262084016531, longitude: 18.406627540010845)
    var testAltitude = 102.0
    var currentCoordinates = CLLocationCoordinate2D()
    var currentAltitude = 0.0
    var distanceLatLong:Double = 0
    var degreesCompass:Double = 0
    
    @IBOutlet weak var ARView: ARSCNView!
    @IBOutlet weak var GPSLoc: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.requestWhenInUseAuthorization()
        
        if(CLLocationManager.locationServicesEnabled()){
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            self.locationManager.startUpdatingLocation()
            self.locationManager.delegate = self
        }
        
        if (CLLocationManager.headingAvailable()) {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
            locationManager.delegate = self
        }
        
        self.ARView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        configuration.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading
        self.ARView.session.run(self.configuration)
        getPosition()
        //TO-DO: Fix with guard let
    }
    
    func getPosition(){
        currentCoordinates = CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        currentAltitude = (locationManager.location?.altitude)!
        distanceLatLong = testCoordinate.DistanceTo(latitudeTo: currentCoordinates.latitude, longitudeTo: currentCoordinates.longitude)
        print(distanceLatLong)
        testAltitude = currentAltitude-testAltitude
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func add(_ sender: Any) {
        let distance = sqrt(pow(distanceLatLong, 2)/2)
        print(distance)
        let node = SCNNode()
        node.geometry = SCNBox(width: 1, height: 0.5, length: 1, chamferRadius: 0)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        node.position = SCNVector3(distance, 0, -distance)
        self.ARView.scene.rootNode.addChildNode(node)
    }
    @IBAction func reset(_ sender: Any) {
        self.restartSession()
        
    }
    
    func restartSession() {
        self.ARView.session.pause()
        self.ARView.scene.rootNode.enumerateChildNodes { node, _ in
            node.removeFromParentNode()
        }
        self.ARView.session.run(self.configuration, options: [.resetTracking, .removeExistingAnchors])
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
    
}
