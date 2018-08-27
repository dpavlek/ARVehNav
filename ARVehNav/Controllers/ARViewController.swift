//
//  ARViewController.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 26/02/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import UIKit
import ARKit
import MapKit
import ARCL

class ARViewController: UIViewController, ARSessionDelegate {
    
    private var currentLocation: CLLocation?
    var destinationCoordinates = CLLocationCoordinate2D(latitude: 45.31262084016531, longitude: 18.406627540010845)
    private var currentCoordinates: CLLocationCoordinate2D?
    private var currentAltitude: Double?
    private var routeSteps = [MKRouteStep]()
    private var routeStepsCount: Int = 0
    private var passedSteps = [MKRouteStep]()
    private var speedManager = SpeedManager()
    private var speedTimer: Timer!
    private var stepTimer: Timer!
    var itemAltitude: Double?
    private var sceneLocationView = SceneLocationView()
    private var routeManager: RouteManager?
    private var lastNode: LocationNode?
    private var headingCamera: Double = 0
    private let viewModel = ARViewControllerModel()
    private var startTime = DispatchTime.now()
    
    @IBOutlet weak var GPSLoc: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneLocationView.run()
        view.addSubview(sceneLocationView)
        
        currentCoordinates = LocationManager.shared.getPosition().Location
        currentAltitude = LocationManager.shared.getPosition().Altitude
        
        GPSLoc.text = NSLocalizedString("loading", comment: "Loading...")
        
        sceneLocationView.session.delegate = self
        
        speedTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(changeColorToSpeed), userInfo: nil, repeats: true)
        
        restartSession()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sceneLocationView.frame = view.bounds
        view.sendSubview(toBack: sceneLocationView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        speedTimer.invalidate()
        stepTimer.invalidate()
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
                    self?.addLastInstruction()
                    self?.routeStepsCount = routeMan.route.steps.count
                    print("Step count: \(self?.routeStepsCount)")
                    self?.stepTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self?.checkSteps), userInfo: nil, repeats: true)
                    self?.addItemNode()
                    let end = DispatchTime.now()
                    let time = Double(end.uptimeNanoseconds - (self?.startTime.uptimeNanoseconds)!) / 1_000_000_000
                    print("Time: \(time)")
                }
            }
        }
    }
    
    func addItemNode() {
        if let altitude = itemAltitude {
            let location = CLLocation(coordinate: destinationCoordinates, altitude: altitude)
            addNodeToScene(destinationLoc: location, tag: "itemNode")
        }
    }
    
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
    }
    
    func restartSession() {
        startTime = DispatchTime.now()
        GPSLoc.text = NSLocalizedString("loading", comment: "Loading...")
        if (stepTimer != nil){
            stepTimer.invalidate()
        }
        sceneLocationView.session.pause()
        for node in sceneLocationView.findNodes(tagged: "roadMarker") {
            sceneLocationView.removeLocationNode(locationNode: node)
        }
        sceneLocationView.run()
        currentLocation = LocationManager.shared.getLastLocation()
        currentAltitude = LocationManager.shared.getLastLocation()?.altitude
        viewModel.getRoute(destination: destinationCoordinates) { [weak self] route in
            self?.routeSteps = route.steps
            self?.routeManager = RouteManager(forRoute: route)
            self?.addARInstruction()
            self?.addAllNodesToScene()
        }
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
            
//            if routeManager.route.steps.count < 500 {
//                for step in routeManager.route.steps {
//                    var nodeLocation = CLLocation()
//                    if let altitude = step.altitude {
//                        if altitude != -1 {
//                            nodeLocation = CLLocation(coordinate: step.coordinates, altitude: altitude)
//                        } else {
//                            if let currentAltitude = LocationManager.shared.getPosition().Altitude {
//                                nodeLocation = CLLocation(coordinate: step.coordinates, altitude: currentAltitude - 1)
//                            }
//                        }
//                    } else if let currentAltitude = currentAltitude {
//                        nodeLocation = CLLocation(coordinate: step.coordinates, altitude: currentAltitude - 1)
//                    } else {
//                        nodeLocation = CLLocation(coordinate: step.coordinates, altitude: 0)
//                    }
//                    addNodeToScene(destinationLoc: nodeLocation, tag: "roadMarker")
//                }
//            } else {
                if routeSteps.count > 2 {
                    for object in sceneLocationView.findNodes(tagged: "roadMarker") {
                        sceneLocationView.removeLocationNode(locationNode: object)
                    }
                    for (index, step) in routeManager.route.steps.enumerated() {
                        if step.coordinates == routeSteps[2].polyline.coordinate {
                            return
                        } else {
                            var nodeLocation = CLLocation()
                            if let altitude = step.altitude {
                                if altitude != -1 {
                                    nodeLocation = CLLocation(coordinate: step.coordinates, altitude: altitude)
                                } else {
                                    if let currentAltitude = LocationManager.shared.getPosition().Altitude {
                                        nodeLocation = CLLocation(coordinate: step.coordinates, altitude: currentAltitude - 1)
                                    }
                                }
                            } else if let currentAltitude = currentAltitude {
                                nodeLocation = CLLocation(coordinate: step.coordinates, altitude: currentAltitude - 1)
                            } else {
                                nodeLocation = CLLocation(coordinate: step.coordinates, altitude: 0)
                            }
                            addNodeToScene(destinationLoc: nodeLocation, tag: "roadMarker")
                            routeManager.route.steps.remove(at: 0)
                        }
                    }
                }
                else{
                                    for step in routeManager.route.steps {
                                        var nodeLocation = CLLocation()
                                        if let altitude = step.altitude {
                                            if altitude != -1 {
                                                nodeLocation = CLLocation(coordinate: step.coordinates, altitude: altitude)
                                            } else {
                                                if let currentAltitude = LocationManager.shared.getPosition().Altitude {
                                                    nodeLocation = CLLocation(coordinate: step.coordinates, altitude: currentAltitude - 1)
                                                }
                                            }
                                        } else if let currentAltitude = currentAltitude {
                                            nodeLocation = CLLocation(coordinate: step.coordinates, altitude: currentAltitude - 1)
                                        } else {
                                            nodeLocation = CLLocation(coordinate: step.coordinates, altitude: 0)
                                        }
                                        addNodeToScene(destinationLoc: nodeLocation, tag: "roadMarker")
                                    }
            }
            }
        //}
    }
    
    @objc func checkSteps() {
        DispatchQueue.global(qos: .background).async {
            if self.routeSteps.count > 0 {
                if let distance = LocationManager.shared.getDistanceTo(locationCoords: (self.routeSteps.first?.polyline.coordinate)!) {
                    if distance < 25 {
                        self.passedSteps.append(self.routeSteps.first!)
                        self.routeSteps.remove(at: 0)
                        self.addARInstruction()
                        self.refreshARObjects()
                    }
                }
                DispatchQueue.main.async {
                    self.GPSLoc.text = self.routeSteps.first?.instructions
                }
            }
        }
    }
    
    func addLastInstruction() {
        if let step = routeManager?.route.steps.last {
            if let altitude = step.altitude {
                if altitude < 0 {
                    if let alt = LocationManager.shared.getPosition().Altitude {
                        let node = viewModel.returnLastInstruction(step: step, altitude: alt + 2)
                        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
                    }
                } else {
                    let node = viewModel.returnLastInstruction(step: step, altitude: altitude + 2)
                    sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
                }
            }
        }
    }
    
    func addARInstruction() {
        for node in sceneLocationView.findNodes(tagged: "instructionNode") {
            sceneLocationView.removeLocationNode(locationNode: node)
        }
        let location = LocationManager.shared.getPosition()
        if let lastStepCoord = location.Location {
            if routeSteps.indices.contains(1) {
                let nextStepCoord = routeSteps[1].polyline.coordinate
                if let step = routeSteps.first {
                    if let altitude = location.Altitude {
                        let node = viewModel.returnInstruction(step: step, altitude: altitude - 1, nextStep: nextStepCoord, lastStep: lastStepCoord)
                        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
                    }
                }
            }
        }
    }
    
    //    func addARInstructions() {
    //        if routeSteps.count > 0 {
    //            for (index, step) in routeSteps.enumerated() {
    //                LocationManager.shared.getAltitude(destination: step.polyline.coordinate) { [weak self] altitude in
    //                    if step == self?.routeSteps.last {
    //                        if let node = self?.viewModel.returnLastInstruction(step: step, altitude: altitude + 2) {
    //                            self?.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
    //                        }
    //                    } else if step != self?.routeSteps.first {
    //                        if let lastStepCoord = self?.routeSteps[index - 1].polyline.coordinate {
    //                            if let nextStepCoord = self?.routeSteps[index + 1].polyline.coordinate {
    //                                if let node = self?.viewModel.returnInstruction(step: step, altitude: altitude + 2, nextStep: nextStepCoord, lastStep: lastStepCoord) {
    //                                    self?.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
    //                                }
    //                            }
    //                        }
    //                    } else if step == self?.routeSteps.first {
    //                        if let node = self?.viewModel.returnFirstInstruction(step: step, altitude: altitude + 2, cameraHeading: (self?.headingCamera)!) {
    //                            self?.sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    @IBAction func changeEulerLeft(_ sender: Any) {
        sceneLocationView.moveSceneHeadingAntiClockwise()
    }
    
    @IBAction func changeEulerRight(_ sender: Any) {
        sceneLocationView.moveSceneHeadingClockwise()
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if let cameraEuler = session.currentFrame?.camera.eulerAngles.y {
            if let heading = LocationManager.shared.heading {
                headingCamera = Double(cameraEuler) + heading
            }
        }
    }
}
