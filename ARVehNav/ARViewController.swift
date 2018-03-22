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
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func add(_ sender: Any) {
        let node = SCNNode()
        node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        node.position = SCNVector3(0.3, 0.3, 0.3)
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
        print("\(locValue.latitude) \(locValue.longitude)")
        DispatchQueue.main.async {
            self.GPSLoc?.text = "\(locValue.latitude) \(locValue.longitude)"
        }
    }
    
}
