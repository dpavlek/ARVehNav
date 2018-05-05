//
//  CLLocationCoordinates+ConvertToMeters.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 03/04/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D{
    func DistanceTo(latitudeTo latTo: Double, longitudeTo longTo: Double) -> (Double){
        let R = 6378.137
        let distanceLat = latTo * Double.pi / 180 - self.latitude * Double.pi / 180
        let distanceLong = longTo * Double.pi / 180 - self.longitude * Double.pi / 180
        let a = sin(distanceLat/2)*sin(distanceLat/2)+cos(latTo*Double.pi/180)*cos(self.latitude*Double.pi/180)*sin(distanceLong/2)*sin(distanceLong/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let d = R * c
        return d*1000
    }
}
