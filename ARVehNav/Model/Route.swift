//
//  Route.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 19/08/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

struct RouteStep {
    let coordinates: CLLocationCoordinate2D
    var altitude: Double?
}

struct Route {
    var steps = [RouteStep]()
}

class RouteManager {
    
    var route = Route()
    var areAltitudesNil = true
    
    init(forRoute route: MKRoute) {
        let steps = calculateAllNodes(steps: route.polyline.coordinates)
        for step in steps {
            self.route.steps.append(RouteStep(coordinates: step, altitude: nil))
        }
    }
    
    func calculateAllNodes(steps: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        var newSteps = [CLLocationCoordinate2D]()
        for (index, step) in steps.enumerated() {
            
            if index < steps.endIndex - 1 {
                let pointA = step
                let pointB = steps[index + 1]
                let diffLat = pointB.latitude - pointA.latitude
                let diffLong = pointB.longitude - pointA.longitude
                
                let distanceAirAB = LocationManager.shared.getAirDistance(currentLocation: pointA, destinationLocation: pointB)
                var numPoints: Int = 0
                if (distanceAirAB > 20) && (distanceAirAB < 100) {
                    numPoints = Int(distanceAirAB / 20)
                } else if distanceAirAB > 100 && distanceAirAB < 1000 {
                    numPoints = Int(distanceAirAB / 50)
                } else if distanceAirAB > 1000 && distanceAirAB < 5000{
                    numPoints = Int(distanceAirAB / 100)
                } else if distanceAirAB > 5000{
                    numPoints = Int(distanceAirAB / 200)
                }
                
                let intervalLat = diffLat / (Double(numPoints) + 1)
                let intervalLong = diffLong / (Double(numPoints) + 1)
                
                if numPoints == 0 {
                    let coordinates = CLLocationCoordinate2D(latitude: pointA.latitude, longitude: pointA.longitude)
                    newSteps.append(coordinates)
                } else {
                    for index in 1...numPoints{
                        let coordinates = CLLocationCoordinate2D(latitude: pointA.latitude + intervalLat * Double(index), longitude: pointA.longitude + intervalLong * Double(index))
                        newSteps.append(coordinates)
                    }
                }
            }
            newSteps.append(step)
        }
        return newSteps
    }
    
    func getAltitudes(onCompletion: @escaping (Bool) -> Void) {
        let count = self.route.steps.count
        var finished = 0
        for (index,step) in self.route.steps.enumerated() {
            LocationManager.shared.getAltitude(destination: step.coordinates) {[weak self] altitude in
                self?.route.steps[index].altitude = altitude
                if altitude != nil{
                    self?.areAltitudesNil = false
                }
                finished += 1
                if(finished == count){
                    onCompletion(true)
                }
            }
        }
    }
}
