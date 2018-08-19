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
import ARCL

class ARViewController: UIViewController, ARSessionDelegate {
    
    var currentLocation: CLLocation?
    var destinationCoordinates = CLLocationCoordinate2D(latitude: 45.31262084016531, longitude: 18.406627540010845)
    var currentCoordinates: CLLocationCoordinate2D?
    private var currentAltitude: Double?
    // var routePoints: [CLLocationCoordinate2D]?
    var routeSteps = [MKRouteStep]()
    var routeStepsCount: Int = 0
    var passedSteps = [MKRouteStep]()
    var speedManager = SpeedManager()
    var speedTimer: Timer!
    var stepTimer: Timer!
    var itemAltitude: Double?
    var sceneLocationView = SceneLocationView()
    var routeManager: RouteManager?
    var lastNode: LocationNode?
    private var nextStep = 0
    
    @IBOutlet weak var GPSLoc: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneLocationView.run()
        view.addSubview(sceneLocationView)
        
        currentCoordinates = LocationManager.shared.getPosition().Location
        currentAltitude = LocationManager.shared.getPosition().Altitude
        
        GPSLoc.text = "Loading..."
        
        sceneLocationView.session.delegate = self
        speedTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(changeColorToSpeed), userInfo: nil, repeats: true)
        
        getRoute { [weak self] route in
            self?.routeSteps = route.steps
            self?.routeManager = RouteManager(forRoute: route)
            self?.addARInstructions()
            self?.addAllNodesToScene()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView.frame = view.bounds
        view.sendSubview(toBack: sceneLocationView)
    }
    
    func getRoute(onCompletion: @escaping (MKRoute) -> Void) {
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
            directions.calculate(completionHandler: { [weak self] response, error in
                guard let response = response else {
                    if let error = error {
                        print(error.localizedDescription)
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
        sceneLocationView.pause()
        sceneLocationView.removeFromSuperview()
    }
    
    @IBAction func add(_ sender: Any) {
        addAllNodesToScene()
    }
    
    func addAllNodesToScene() {
        if let routeMan = routeManager {
            routeMan.getAltitudes { [weak self] finished in
                if finished {
                    self?.routeStepsCount = routeMan.route.steps.count
                    print(self?.routeStepsCount)
                    self?.stepTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self?.checkSteps), userInfo: nil, repeats: true)
                    self?.refreshARObjects()
                }
            }
        }
    }
    
    //    func addAllNodesToScene() {
    //        if let steps = routePoints {
    //            for (index, step) in steps.enumerated() {
    //
    //                if index < steps.endIndex - 1 {
    //                    let pointA = step
    //                    let pointB = steps[index + 1]
    //                    let diffLat = pointB.latitude - pointA.latitude
    //                    let diffLong = pointB.longitude - pointA.longitude
    //
    //                    let distanceAirAB = locationManager.getAirDistance(currentLocation: pointA, destinationLocation: pointB)
    //
    //                    var numPoints: Int = 0
    //                    if (distanceAirAB > 10) && (distanceAirAB < 20) {
    //                        numPoints = Int(distanceAirAB / 10)
    //                    }
    //                    if (distanceAirAB > 20) && (distanceAirAB < 100) {
    //                        numPoints = Int(distanceAirAB / 20)
    //                    } else if distanceAirAB > 100 {
    //                        numPoints = Int(distanceAirAB / 50)
    //                    }
    //
    //                    let intervalLat = diffLat / (Double(numPoints) + 1)
    //                    let intervalLong = diffLong / (Double(numPoints) + 1)
    //
    //                    if numPoints == 0 {
    //                        let coordinates = CLLocationCoordinate2D(latitude: pointA.latitude, longitude: pointA.longitude)
    //                        locationManager.getAltitude(destination: coordinates) { [weak self] altitude in
    //                            self?.GPSLoc.text = "Loading..."
    //                            let point = CLLocation(coordinate: coordinates, altitude: altitude)
    //                            if index == steps.endIndex {
    //                                self?.addNodeToScene(destinationLoc: point, tag: "itemNode")
    //                            } else {
    //                                self?.addNodeToScene(destinationLoc: point, tag: "roadMarker")
    //                            }
    //                        }
    //                    } else {
    //                        for index in 1...numPoints {
    //                            let coordinates = CLLocationCoordinate2D(latitude: pointA.latitude + intervalLat * Double(index), longitude: pointA.longitude + intervalLong * Double(index))
    //
    //                            locationManager.getAltitude(destination: coordinates) { [weak self] altitude in
    //                                let point = CLLocation(coordinate: coordinates, altitude: altitude)
    //                                if index == steps.endIndex {
    //                                    self?.addNodeToScene(destinationLoc: point, tag: "itemNode")
    //                                } else {
    //                                    self?.addNodeToScene(destinationLoc: point, tag: "roadMarker")
    //                                }
    //                                self?.GPSLoc.text = "Loading..."
    //                            }
    //                        }
    //                    }
    //                } else {
    //                    let coordinates = CLLocationCoordinate2D(latitude: step.latitude, longitude: step.longitude)
    //                    if let ialt = itemAltitude {
    //                        GPSLoc.text = "Loading..."
    //                        let point = CLLocation(coordinate: coordinates, altitude: ialt)
    //                        addNodeToScene(destinationLoc: point, tag: "itemNode")
    //
    //                    } else {
    //                        locationManager.getAltitude(destination: coordinates) { [weak self] altitude in
    //                            self?.GPSLoc.text = "Loading..."
    //                            let point = CLLocation(coordinate: coordinates, altitude: altitude)
    //                            self?.addNodeToScene(destinationLoc: point, tag: "itemNode")
    //                        }
    //                    }
    //                }
    //                GPSLoc.text = ""
    //            }
    //        }
    //    }
    
    func addNodeToScene(destinationLoc: CLLocation, tag: String) {
        let node = LocationNode(location: destinationLoc)
        node.tag = tag
        node.geometry = SCNCylinder(radius: 4, height: 0.2)
        if tag == "itemNode" {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        } else {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        }
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
    }
    
    @IBAction func reset(_ sender: Any) {
        restartSession()
        sceneLocationView.scene.rootNode.eulerAngles.y = 0
        currentLocation = LocationManager.shared.getLastLocation()
        currentAltitude = LocationManager.shared.getLastLocation()?.altitude
        getRoute { [weak self] route in
            self?.routeSteps = route.steps
            self?.addAllNodesToScene()
            self?.addARInstructions()
        }
    }
    
    func restartSession() {
        sceneLocationView.session.pause()
        for node in sceneLocationView.findNodes(tagged: "roadMarker") {
            sceneLocationView.removeLocationNode(locationNode: node)
        }
        sceneLocationView.run()
    }
    
    @objc func changeColorToSpeed() {
        if let location = LocationManager.shared.getLastLocation() {
            var currSpeed = location.speed
            let coordinates = location.coordinate
            print(currSpeed)
            if currSpeed >= 0 {
                currSpeed = currSpeed / 3.6
                speedManager.getLocationID(location: coordinates) {
                    osm_id in
                    self.speedManager.getSpeedLimit(osmID: osm_id) {
                        speed in
                        let nodes = self.sceneLocationView.findNodes(tagged: "roadMarker")
                        let maxSpeed = Double(speed) * 1.1
                        for node in nodes {
                            if node == nodes.last {
                                return
                            }
                            if (currSpeed > Double(speed)) && (currSpeed < maxSpeed) {
                                DispatchQueue.main.async {
                                    node.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
                                }
                            } else if currSpeed > Double(maxSpeed) {
                                DispatchQueue.main.async {
                                    node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
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
    
    func refreshARObjects() {
        if let routeManager = routeManager {
            
            for object in sceneLocationView.findNodes(tagged: "roadMarker") {
                sceneLocationView.removeLocationNode(locationNode: object)
            }
            
            if routeManager.route.steps.count < 200 {
                for step in routeManager.route.steps {
                    var nodeLocation = CLLocation()
                    if let altitude = step.altitude {
                        nodeLocation = CLLocation(coordinate: step.coordinates, altitude: altitude)
                    } else if let currentAltitude = currentAltitude {
                        nodeLocation = CLLocation(coordinate: step.coordinates, altitude: currentAltitude - 2)
                    } else {
                        nodeLocation = CLLocation(coordinate: step.coordinates, altitude: 0)
                    }
                    addNodeToScene(destinationLoc: nodeLocation, tag: "roadMarker")
                }
            } else {
                if routeSteps.count > 2 {
                    for (index, step) in routeManager.route.steps.enumerated() {
                        if step.coordinates == routeSteps[2].polyline.coordinate {
                            return
                        } else {
                            var nodeLocation = CLLocation()
                            if let altitude = step.altitude {
                                nodeLocation = CLLocation(coordinate: step.coordinates, altitude: altitude)
                            } else if let currentAltitude = currentAltitude {
                                nodeLocation = CLLocation(coordinate: step.coordinates, altitude: currentAltitude - 2)
                            } else {
                                nodeLocation = CLLocation(coordinate: step.coordinates, altitude: 0)
                            }
                            addNodeToScene(destinationLoc: nodeLocation, tag: "roadMarker")
                            routeManager.route.steps.remove(at: index)
                        }
                    }
                }
            }
        }
    }
    
    @objc func checkSteps() {
        DispatchQueue.global(qos: .background).async {
            if self.routeSteps.count > 0 {
                if let distance = LocationManager.shared.getDistanceTo(locationCoords: (self.routeSteps.first?.polyline.coordinate)!) {
                    if distance < 5 {
                        self.passedSteps.append(self.routeSteps.first!)
                        self.routeSteps.remove(at: 0)
                        self.refreshARObjects()
                    }
                }
                DispatchQueue.main.async {
                    self.GPSLoc.text = self.routeSteps.first?.instructions
                }
            }
        }
    }
    
    func addARInstructions() {
        if routeSteps.count > 0 {
            for (index, step) in routeSteps.enumerated() {
                LocationManager.shared.getAltitude(destination: step.polyline.coordinate) { [weak self] altitude in
                    if step == self?.routeSteps.last {
                        let location = CLLocation(coordinate: step.polyline.coordinate, altitude: altitude + 6)
                        let node = LocationNode(location: location)
                        node.tag = "instructionNode"
                        let instruction = SCNPlane(width: 6, height: 6)
                        instruction.firstMaterial?.diffuse.contents = UIImage(named: "RedArrow")
                        instruction.firstMaterial?.isDoubleSided = true
                        node.geometry = instruction
                        node.constraints = [SCNBillboardConstraint()]
                        self?.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
                    } else if step != self?.routeSteps.first {
                        let lastStepCoord = self?.routeSteps[index - 1].polyline.coordinate
                        let nextStepCoord = self?.routeSteps[index + 1].polyline.coordinate
                        let location = CLLocation(coordinate: step.polyline.coordinate, altitude: altitude + 2)
                        let node = LocationNode(location: location)
                        node.tag = "instructionNode"
                        let instruction = SCNPlane(width: 6, height: 6)
                        if (LocationManager.shared.getDirection(previous: lastStepCoord!, current: step.polyline.coordinate, next: nextStepCoord!)) {
                            instruction.firstMaterial?.diffuse.contents = UIImage(named: "RightArrow")
                        } else {
                            instruction.firstMaterial?.diffuse.contents = UIImage(named: "LeftArrow")
                        }
                        instruction.firstMaterial?.isDoubleSided = true
                        node.geometry = instruction
                        node.constraints = [SCNBillboardConstraint()]
                        self?.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
                    } else {
                        if let heading = LocationManager.shared.heading {
                            if let currentLoc = self?.currentLocation {
                                let headingRadians = heading * (Double.pi / 180)
                                let x = 2 * cos(headingRadians) + currentLoc.coordinate.latitude
                                let y = 2 * sin(headingRadians) + currentLoc.coordinate.longitude
                                let coordinate = CLLocationCoordinate2D(latitude: x, longitude: y)
                                let location = CLLocation(coordinate: coordinate, altitude: altitude)
                                let node = LocationNode(location: location)
                                node.geometry = SCNBox(width: 4, height: 2, length: 4, chamferRadius: 0)
                                node.geometry?.firstMaterial?.diffuse.contents = UIColor.red
                                self?.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func changeEulerLeft(_ sender: Any) {
        sceneLocationView.moveSceneHeadingAntiClockwise()
    }
    
    @IBAction func changeEulerRight(_ sender: Any) {
        sceneLocationView.moveSceneHeadingClockwise()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
}
