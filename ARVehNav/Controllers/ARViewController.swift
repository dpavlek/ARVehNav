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
import MapKit
import SwiftyJSON
import Alamofire

class ARViewController: UIViewController {
    
    var locationManager = LocationManager()
    var currentLocation: CLLocation?
    var destinationCoordinates = CLLocationCoordinate2D(latitude: 45.31262084016531, longitude: 18.406627540010845)
    var currentCoordinates: CLLocationCoordinate2D?
    private var currentAltitude: Double?
    var routePoints: [CLLocationCoordinate2D]?
    var routeSteps: [MKRouteStep]?
    var speedManager = SpeedManager()
    var speedTimer: Timer!
    var itemAltitude: Double?
    
    @IBOutlet weak var ARView: ARSCNView!
    @IBOutlet weak var GPSLoc: UILabel!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentCoordinates = locationManager.getPosition().Location
        currentAltitude = locationManager.getPosition().Altitude
        configuration.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading
        ARView.session.run(configuration)
        speedTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(changeColorToSpeed), userInfo: nil, repeats: true)
        getRoute(){ [weak self] route in
            self?.routePoints = route.polyline.coordinates
            self?.routeSteps = route.steps
            self?.restartSession()
            self?.addAllNodesToScene()
        }
    }
    
    func getRoute(onCompletion: @escaping (MKRoute)->Void){
        if let curCoord = currentCoordinates {
            let startPlace = MKPlacemark(coordinate: curCoord)
            let destPlace = MKPlacemark(coordinate: destinationCoordinates)
            let startItem = MKMapItem(placemark: startPlace)
            let destItem = MKMapItem(placemark: destPlace)
            let routeRequest = MKDirectionsRequest()
            routeRequest.source = startItem
            routeRequest.destination = destItem
            routeRequest.transportType = .automobile
            
            let directions = MKDirections(request: routeRequest)
            directions.calculate(completionHandler: { response, error in
                guard let response = response else {
                    if let error = error {
                        print("Error in getting route:" + error.localizedDescription)
                    }
                    return
                }
                
                let route = response.routes[0]
                onCompletion(route)
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        speedTimer.invalidate()
    }
    
    @IBAction func add(_ sender: Any) {
        addAllNodesToScene()
    }
    
//    func addAllNodesToScene() {
//        if let steps = routePoints {
//            for (_, step) in steps.enumerated() {
//                let point = CLLocationCoordinate2D(latitude: step.latitude, longitude: step.longitude)
//                if let currentAltitude = currentAltitude {
//                    addNodeToScene(destinationLoc: point, destinationAltitude: currentAltitude - 2, item: false)
//                    /* locationManager.getAltitude(currentAltitude: currentAltitude, destination: point) { [weak self] altitude in
//                     self?.GPSLoc.text = "Loading: \(index) / \(numPoints)"
//                     self?.addNodeToScene(destinationLoc: point, destinationAltitude: altitude)
//                     } */
//                }
//            }
//            if let itemAlt = itemAltitude {
//                addNodeToScene(destinationLoc: destinationCoordinates, destinationAltitude: itemAlt, item:true)
//            }
//        }
//        GPSLoc.text = "Gotovo"
//    }
    
        func addAllNodesToScene() {
            print("Distances:")
            if let steps = routePoints {
                for (index, step) in steps.enumerated() {
                    if index < steps.endIndex - 1 {
                        let pointA = step
                        let pointB = steps[index + 1]
                        let diffLat = pointB.latitude - pointA.latitude
                        let diffLong = pointB.longitude - pointA.longitude
    
                        let distanceAirAB = locationManager.getAirDistance(currentLocation: pointA, destinationLocation: pointB)
                        print(distanceAirAB)
                        var numPoints: Int = 0
                        if (distanceAirAB > 20) && (distanceAirAB < 50) {
                            numPoints = Int(distanceAirAB / 15)
                        } else if distanceAirAB > 50 && distanceAirAB < 100 {
                            numPoints = Int(distanceAirAB / 20)
                        } else if distanceAirAB > 100 {
                            numPoints = Int(distanceAirAB / 50)
                        }
    
                        let intervalLat = diffLat / (Double(numPoints) + 1)
                        let intervalLong = diffLong / (Double(numPoints) + 1)
    
                        if numPoints == 0 {
                            if let currentAltitude = currentAltitude {
                                let point = CLLocationCoordinate2D(latitude: pointA.latitude, longitude: pointA.longitude)
                                addNodeToScene(destinationLoc: point, destinationAltitude: currentAltitude - 2, item: false)
                                /* locationManager.getAltitude(currentAltitude: currentAltitude, destination: point) { [weak self] altitude in
                                 self?.GPSLoc.text = "Loading: \(index) / \(numPoints)"
                                 self?.addNodeToScene(destinationLoc: point, destinationAltitude: altitude)
                                 } */
                            }
                        } else {
                            for index in 1...numPoints {
                                let point = CLLocationCoordinate2D(latitude: pointA.latitude + intervalLat * Double(index), longitude: pointA.longitude + intervalLong * Double(index))
                                if let currentAltitude = currentAltitude {
                                    addNodeToScene(destinationLoc: point, destinationAltitude: currentAltitude - 2, item:false)
                                    /* locationManager.getAltitude(currentAltitude: currentAltitude, destination: point) { [weak self] altitude in
                                     self?.GPSLoc.text = "Loading: \(index) / \(numPoints)"
                                     self?.addNodeToScene(destinationLoc: point, destinationAltitude: altitude)
                                     } */
                                }
                            }
                        }
                        GPSLoc.text = "Gotovo"
                    }
                }
            }
        }
    
    func addNodeToScene(destinationLoc: CLLocationCoordinate2D, destinationAltitude: Double, item: Bool) {
        let node = SCNNode()
        node.geometry = SCNBox(width: 4, height: 0.2, length: 4, chamferRadius: 0.1)
        if(item){
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        }
        else{
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        }
        if let cLoc = currentCoordinates {
            var distance = locationManager.getDistance(currentLocation: cLoc, destinationLocation: destinationLoc)
            if destinationLoc.latitude > cLoc.latitude {
                distance.lat = -distance.lat
            }
            if destinationLoc.longitude < cLoc.longitude {
                distance.long = -distance.long
            }
            if let currAltitude = currentAltitude {
                let altitude = locationManager.getAltitudeDiff(currentAltitude: currAltitude, destinationAltitude: destinationAltitude)
                node.position = SCNVector3(distance.long, altitude, distance.lat)
            }
        }
        ARView.scene.rootNode.addChildNode(node)
    }
    
    @IBAction func reset(_ sender: Any) {
        restartSession()
        ARView.scene.rootNode.eulerAngles.y = 0
        currentLocation = locationManager.getLastLocation()
        currentAltitude = locationManager.getLastLocation()?.altitude
        getRoute(){ [weak self] route in
            self?.routePoints = route.polyline.coordinates
            self?.routeSteps = route.steps
            self?.addAllNodesToScene()
        }
    }
    
    func restartSession() {
        ARView.session.pause()
        ARView.scene.rootNode.enumerateChildNodes { node, _ in
            node.removeFromParentNode()
        }
        ARView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    @objc func changeColorToSpeed() {
        if let location = locationManager.getLastLocation() {
            var currSpeed = location.speed
            let coordinates = location.coordinate
            print(currSpeed)
            if currSpeed >= 0 {
                currSpeed = currSpeed / 3.6
                speedManager.getLocationID(location: coordinates) {
                    osm_id in
                    self.speedManager.getSpeedLimit(osmID: osm_id) {
                        speed in
                        self.ARView.scene.rootNode.enumerateChildNodes { node, _ in
                            if currSpeed > Double(speed) {
                                DispatchQueue.main.async {
                                    node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                                }
                            } else if currSpeed == Double(speed) {
                                DispatchQueue.main.async {
                                    node.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
                                }
                            } else if currSpeed < Double(speed) {
                                DispatchQueue.main.async {
                                    node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
    
    @IBAction func changeEulerLeft(_ sender: Any) {
        ARView.scene.rootNode.eulerAngles.y += Float(1) * .pi / 180
    }
    
    @IBAction func changeEulerRight(_ sender: Any) {
        ARView.scene.rootNode.eulerAngles.y -= Float(1) * .pi / 180
    }
}
