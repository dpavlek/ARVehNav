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
    
    var testCoordinate = CLLocationCoordinate2D(latitude: 45.31232301758361, longitude: 18.405930981092297)
    var testAltitude = 102.0
    var currentCoordinates = CLLocationCoordinate2D()
    var currentAltitude = 0.0
    var distanceLatLong:(Latitude:Double,Longitude:Double) = (0,0)
    
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
        
        self.ARView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.ARView.session.run(self.configuration)
        //TO-DO: Fix with guard let
        currentCoordinates = CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        currentAltitude = (locationManager.location?.altitude)!
        distanceLatLong = testCoordinate.ConvertToMeters(latitudeTo: currentCoordinates.latitude, longitudeTo: currentCoordinates.longitude)
        print(distanceLatLong)
        testAltitude = currentAltitude-testAltitude
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func add(_ sender: Any) {
        let node = SCNNode()
        node.geometry = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 0)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        node.position = SCNVector3(distanceLatLong.Latitude, 0, distanceLatLong.Longitude)
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
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        DispatchQueue.main.async {
            self.GPSLoc?.text = "\(locValue.latitude) \(locValue.longitude)"
        }
    }
    
}
