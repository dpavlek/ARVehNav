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
    
    func returnLastInstruction(step: MKRouteStep, altitude: Double) -> LocationNode {
        let location = CLLocation(coordinate: step.polyline.coordinate, altitude: altitude + 6)
        let node = LocationNode(location: location)
        node.tag = "instructionNode"
        let instruction = SCNPlane(width: 6, height: 6)
        instruction.firstMaterial?.diffuse.contents = UIImage(named: "RedArrow")
        instruction.firstMaterial?.isDoubleSided = true
        node.geometry = instruction
        node.constraints = [SCNBillboardConstraint()]
        return node
    }
    
    func returnInstruction(step: MKRouteStep, altitude: Double, nextStep: CLLocationCoordinate2D, lastStep: CLLocationCoordinate2D) -> LocationNode {
        let location = CLLocation(coordinate: step.polyline.coordinate, altitude: altitude + 2)
        let node = LocationNode(location: location)
        node.tag = "instructionNode"
        let instruction = SCNPlane(width: 6, height: 6)
        if LocationManager.shared.getDirection(previous: lastStep, current: step.polyline.coordinate, next: nextStep) {
            instruction.firstMaterial?.diffuse.contents = UIImage(named: "RightArrow")
        } else {
            instruction.firstMaterial?.diffuse.contents = UIImage(named: "LeftArrow")
        }
        instruction.firstMaterial?.isDoubleSided = true
        node.geometry = instruction
        node.constraints = [SCNBillboardConstraint()]
        return node
    }
}