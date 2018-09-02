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

class ARViewController: UIViewController, ARSessionDelegate, MKMapViewDelegate {
    
    var destinationCoordinates = CLLocationCoordinate2D(latitude: 45.31262084016531, longitude: 18.406627540010845)
    private var routeSteps = [MKRouteStep]()
    private var routeStepsCount: Int = 0
    private var passedSteps = [MKRouteStep]()
    private var speedManager = SpeedManager()
    private var speedTimer: Timer!
    private var stepTimer: Timer!
    private var routeTimer: Timer!
    private var sceneLocationView = SceneLocationView()
    private var routeManager: RouteManager?
    private let viewModel = ARViewControllerModel()
    
    @IBOutlet weak var GPSLoc: UILabel!
    @IBOutlet weak var resetBtn: UIButton!
    @IBOutlet weak var miniMap: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        miniMap.delegate = self
        miniMap.alpha = 0.8
        sceneLocationView.run()
        view.addSubview(sceneLocationView)
        
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
        if stepTimer != nil {
            stepTimer.invalidate()
        }
        if routeTimer != nil {
            routeTimer.invalidate()
        }
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
                    self?.refreshARObjects()
                    self?.stepTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self?.checkSteps), userInfo: nil, repeats: true)
                    self?.routeTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self?.checkRoute), userInfo: nil, repeats: true)
                    self?.resetBtn.isEnabled = true
                }
            }
        }
    }
    
    func addNodeToScene(destinationLoc: CLLocation, tag: String) {
        let node = LocationNode(location: destinationLoc)
        node.tag = tag
        node.geometry = SCNCylinder(radius: 3, height: 0.2)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        node.isHidden = true
        node.opacity = 0.8
        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
    }
    
    @IBAction func reset(_ sender: Any) {
        restartSession()
    }
    
    func restartSession() {
        resetBtn.isEnabled = false
        GPSLoc.text = NSLocalizedString("loading", comment: "Loading...")
        if stepTimer != nil {
            stepTimer.invalidate()
        }
        if routeTimer != nil {
            routeTimer.invalidate()
        }
        sceneLocationView.session.pause()
        for node in sceneLocationView.findNodes(tagged: "roadMarker") {
            sceneLocationView.removeLocationNode(locationNode: node)
        }
        for node in sceneLocationView.findNodes(tagged: "lastNode") {
            sceneLocationView.removeLocationNode(locationNode: node)
        }
        sceneLocationView.run()
        viewModel.getRoute(destination: destinationCoordinates) { [weak self] route in
            self?.routeSteps = route.steps
            self?.routeManager = RouteManager(forRoute: route)
            self?.addARInstruction()
            self?.setMap(route: route)
            self?.addAllNodesToScene()
        }
    }
    
    func setMap(route: MKRoute) {
        let destAnnotation = MKPointAnnotation()
        destAnnotation.coordinate = destinationCoordinates
        miniMap.showAnnotations([destAnnotation], animated: true)
        miniMap.add(route.polyline, level: MKOverlayLevel.aboveRoads)
        miniMap.setUserTrackingMode(.followWithHeading, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor.blue
        renderer.lineWidth = 4.0
        return renderer
    }
    
    @objc func changeColorToSpeed() {
        if let location = LocationManager.shared.lastLocation {
            var currSpeed = location.speed
            let coordinates = location.coordinate
            if currSpeed >= 0 {
                currSpeed = currSpeed / 3.6
                speedManager.getLocationID(location: coordinates) {
                    osm_id in
                    self.speedManager.getSpeedLimit(osmID: osm_id) {
                        speed in
                        let nodes = self.sceneLocationView.findNodes(tagged: "roadMarker")
                        let maxSpeed = Double(speed) * 1.1
                        print("Current speed: \(currSpeed) Max: \(maxSpeed)")
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
            if routeManager.route.steps.count > 200 {
                for object in sceneLocationView.findNodes(tagged: "roadMarker") {
                    sceneLocationView.removeLocationNode(locationNode: object)
                }
                var i = 0
                for (index, step) in routeManager.route.steps.enumerated() {
                    if i == 200 {
                        print(routeManager.route.steps.count)
                        return
                    } else {
                        var nodeLocation = CLLocation()
                        if let altitude = step.altitude {
                            nodeLocation = CLLocation(coordinate: step.coordinates, altitude: altitude)
                        } else if let currentAltitude = LocationManager.shared.getPosition().Altitude {
                            nodeLocation = CLLocation(coordinate: step.coordinates, altitude: currentAltitude - 1)
                        } else {
                            nodeLocation = CLLocation(coordinate: step.coordinates, altitude: 0)
                        }
                        addNodeToScene(destinationLoc: nodeLocation, tag: "roadMarker")
                        routeManager.route.steps.remove(at: 0)
                        i += 1
                    }
                }
            } else {
                for step in routeManager.route.steps {
                    var nodeLocation = CLLocation()
                    if let altitude = step.altitude {
                        nodeLocation = CLLocation(coordinate: step.coordinates, altitude: altitude)
                    } else if let currentAltitude = LocationManager.shared.getPosition().Altitude {
                        nodeLocation = CLLocation(coordinate: step.coordinates, altitude: currentAltitude - 1)
                    } else {
                        nodeLocation = CLLocation(coordinate: step.coordinates, altitude: 0)
                    }
                    addNodeToScene(destinationLoc: nodeLocation, tag: "roadMarker")
                    routeManager.route.steps.remove(at: 0)
                    if routeTimer != nil {
                        routeTimer.invalidate()
                    }
                }
            }
        }
    }
    
    @objc func checkSteps() {
        DispatchQueue.global(qos: .background).async {
            if self.routeSteps.count > 0 {
                if let distance = LocationManager.shared.getDistanceTo(locationCoords: (self.routeSteps.first?.polyline.coordinate)!) {
                    if distance < 20 {
                        self.passedSteps.append(self.routeSteps.first!)
                        self.routeSteps.remove(at: 0)
                        self.addARInstruction()
                    }
                }
                DispatchQueue.main.async {
                    self.GPSLoc.text = self.routeSteps.first?.instructions
                }
            }
        }
    }
    
    @objc func checkRoute() {
        if (routeManager?.route.steps.count)! > 0 {
            if let distance = LocationManager.shared.getDistanceTo(locationCoords: (self.routeManager?.route.steps.first?.coordinates)!) {
                if distance < 25 {
                    print(distance)
                    refreshARObjects()
                }
            }
        }
    }
    
    func addLastInstruction() {
        if let step = routeManager?.route.steps.last {
            if let altitude = step.altitude {
                let node = viewModel.returnLastInstruction(step: step, altitude: altitude + 2)
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
            } else if let altitude = LocationManager.shared.getPosition().Altitude {
                let node = viewModel.returnLastInstruction(step: step, altitude: altitude)
                sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
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
                        let node = viewModel.returnInstruction(step: step, altitude: altitude, nextStep: nextStepCoord, lastStep: lastStepCoord)
                        sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: node)
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
        if let camPosition = session.currentFrame?.camera.transform.columns.3 {
            if let altitudesAreNil = routeManager?.areAltitudesNil {
                if altitudesAreNil {
                    for node in sceneLocationView.findNodes(tagged: "roadMarker") {
                        let position = SCNVector3(camPosition.x, camPosition.y, camPosition.z)
                        let distance = viewModel.distanceToNode(from: position, to: node.presentation.worldPosition)
                        if distance < 50 {
                            node.isHidden = false
                        } else {
                            node.isHidden = true
                        }
                        node.position.y = camPosition.y - 1
                    }
                    for node in sceneLocationView.findNodes(tagged: "instructionNode") {
                        node.position.y = camPosition.y + 1
                    }
                    for node in sceneLocationView.findNodes(tagged: "lastNode") {
                        node.position.y = camPosition.y + 2
                    }
                }
            } else {
                for node in sceneLocationView.findNodes(tagged: "roadMarker") {
                    if abs(node.position.y - camPosition.y) < 2 {
                        node.position.y = camPosition.y - 1
                    }
                }
            }
        }
    }
}
