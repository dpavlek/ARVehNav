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

class ARViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var destinationCoordinates = CLLocationCoordinate2D(latitude: 45.31262084016531, longitude: 18.406627540010845)
    var currentCoordinates: CLLocationCoordinate2D?
    private var currentAltitude: Double?
    var degreesCompass: Double = 0
    var routeSteps: [MKRouteStep]?
    
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
        configuration.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading
        ARView.session.run(configuration)
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
                        print("Error in getting route:" + error.localizedDescription)
                    }
                    return
                }
                
                let route = response.routes[0]
                self?.routeSteps = route.steps
                for step in route.steps {
                    print("Step: \(step.polyline.coordinate)")
                }
                self?.restartSession()
                self?.addAllNodesToScene()
            })
        }
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
    
    func getAirDistance(currentLocation: CLLocationCoordinate2D, destinationLocation: CLLocationCoordinate2D) -> Double {
        return currentLocation.DistanceTo(latitudeTo: destinationLocation.latitude, longitudeTo: destinationLocation.longitude)
    }
    
    func getAltitude(currentAltitude: Double, destination: CLLocationCoordinate2D, onCompletion: @escaping ((Double) -> Void)) {
        var altitude = currentAltitude - 5
        Alamofire.request(Constants.getElevation(coordinates: destination)).responseJSON { response in
            switch response.result {
                
            case .success(let data):
                let response = JSON(data)
                altitude = response["elevationProfile"]["height"].doubleValue
                onCompletion(altitude)
                
            case .failure(let error):
                print(error)
                onCompletion(altitude)
            }
            
        }
    }
    
    func getAltitudeDiff(currentAltitude: Double, destinationAltitude: Double) -> Double {
        return destinationAltitude - currentAltitude
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func add(_ sender: Any) {
        addAllNodesToScene()
    }
    
    func addAllNodesToScene() {
        if let steps = routeSteps {
            for (index, step) in steps.enumerated() {
                if index < steps.endIndex - 1 {
                    let pointA = step.polyline.coordinate
                    let pointB = steps[index + 1].polyline.coordinate
                    let diffLat = pointB.latitude - pointA.latitude
                    let diffLong = pointB.longitude - pointA.longitude
                    
                    let distanceAirAB = getAirDistance(currentLocation: pointA, destinationLocation: pointB)
                    var numPoints: Int
                    if distanceAirAB < 1000 {
                        numPoints = Int(distanceAirAB / 10)
                    } else if distanceAirAB > 1000 && distanceAirAB < 5000 {
                        numPoints = Int(distanceAirAB / 100)
                    } else {
                        numPoints = Int(distanceAirAB / 200)
                    }
                    
                    let intervalLat = diffLat / (Double(numPoints) + 1)
                    let intervalLong = diffLong / (Double(numPoints) + 1)
                    
                    if numPoints == 0 {
                        if let currentAltitude = currentAltitude {
                            let point = CLLocationCoordinate2D(latitude: pointA.latitude, longitude: pointA.longitude)
                            addNodeToScene(destinationLoc: point, destinationAltitude: currentAltitude - 2)
                             /*getAltitude(currentAltitude: currentAltitude, destination: point) { [weak self] altitude in
                             self?.GPSLoc.text = "Loading: \(index) / \(numPoints)"
                             self?.addNodeToScene(destinationLoc: point, destinationAltitude: altitude)
                             }*/
                        }
                    } else {
                        for index in 1...numPoints {
                            let point = CLLocationCoordinate2D(latitude: pointA.latitude + intervalLat * Double(index), longitude: pointA.longitude + intervalLong * Double(index))
                            if let currentAltitude = currentAltitude {
                                addNodeToScene(destinationLoc: point, destinationAltitude: currentAltitude - 2)
                                 /*getAltitude(currentAltitude: currentAltitude, destination: point) { [weak self] altitude in
                                 self?.GPSLoc.text = "Loading: \(index) / \(numPoints)"
                                 self?.addNodeToScene(destinationLoc: point, destinationAltitude: altitude)
                                 }*/
                            }
                        }
                    }
                    GPSLoc.text = "Gotovo"
                }
            }
        }
    }
    
    func addNodeToScene(destinationLoc: CLLocationCoordinate2D, destinationAltitude: Double) {
        let node = SCNNode()
        node.geometry = SCNBox(width: 4, height: 0.2, length: 4, chamferRadius: 0.1)
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        if let cLoc = currentCoordinates {
            var distance = getDistance(currentLocation: cLoc, destinationLocation: destinationLoc)
            if destinationLoc.latitude > cLoc.latitude {
                distance.lat = -distance.lat
            }
            if destinationLoc.longitude < cLoc.longitude {
                distance.long = -distance.long
            }
            if let currAltitude = currentAltitude {
                let altitude = getAltitudeDiff(currentAltitude: currAltitude, destinationAltitude: destinationAltitude)
                node.position = SCNVector3(distance.long, altitude, distance.lat)
            }
        }
        ARView.scene.rootNode.addChildNode(node)
    }
    
    @IBAction func reset(_ sender: Any) {
        restartSession()
        ARView.scene.rootNode.eulerAngles.y = 0
        addAllNodesToScene()
    }
    
    func restartSession() {
        ARView.session.pause()
        ARView.scene.rootNode.enumerateChildNodes { node, _ in
            node.removeFromParentNode()
        }
        ARView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
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
    
    @IBAction func changeEulerLeft(_ sender: Any) {
        ARView.scene.rootNode.eulerAngles.y += Float(1) * .pi / 180
    }
    
    @IBAction func changeEulerRight(_ sender: Any) {
        ARView.scene.rootNode.eulerAngles.y -= Float(1) * .pi / 180
    }
}
