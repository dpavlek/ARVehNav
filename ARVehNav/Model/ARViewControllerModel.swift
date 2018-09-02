//
//  ARViewControllerModel.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 19/08/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import CoreLocation
import ARCL
import MapKit
import ARKit

class ARViewControllerModel {
    
    func getRoute(destination destinationCoordinates: CLLocationCoordinate2D, onCompletion: @escaping (MKRoute) -> Void) {
        let curCoord = LocationManager.shared.getPosition().Location
        guard let currentCoordinates = curCoord else{
           return
        }
        let startPlace = MKPlacemark(coordinate: currentCoordinates)
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
                    print(error.localizedDescription)
                }
                return
            }
            
            let route = response.routes[0]
            onCompletion(route)
        })
    }
    
    func returnLastInstruction(step: RouteStep, altitude: Double) -> LocationNode {
        let location = CLLocation(coordinate: step.coordinates, altitude: altitude + 6)
        let arrow = UIImage(named: "RedArrow")!
        let node = LocationAnnotationNode(location: location, image: arrow)
        node.tag = "lastNode"
        node.scaleRelativeToDistance = true
        node.opacity = 0.8
        return node
    }
    
    func returnInstruction(step: MKRouteStep, altitude: Double, nextStep: CLLocationCoordinate2D, lastStep: CLLocationCoordinate2D) -> LocationNode {
        let location = CLLocation(coordinate: step.polyline.coordinate, altitude: altitude + 4)
        let image: UIImage
        switch LocationManager.shared.getDirection(previous: lastStep, current: step.polyline.coordinate, next: nextStep) {
        case .right:
            image = UIImage(named: "RightArrow")!
        case .left:
            image = UIImage(named: "LeftArrow")!
        case .straight:
            image = UIImage(named: "StraightArrow")!
        }
        let node = LocationAnnotationNode(location: location, image: image)
        node.scaleRelativeToDistance = true
        node.tag = "instructionNode"
        node.opacity = 0.8
        return node
    }
    
    func distanceToNode(from node1: SCNVector3, to node2: SCNVector3)->Float{
        let distance = SCNVector3(node1.x - node2.x, node1.y - node2.y, node1.z - node2.z)
        return sqrtf(distance.x * distance.x + distance.y * distance.y + distance.z * distance.z)
    }
}
