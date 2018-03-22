//
//  Item.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 16/03/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import CoreLocation

struct Item{
    let Name: String
    let ID: String
    var Location: CLLocationCoordinate2D?
    
    mutating func setLocationFromFloat(latitude: Double, longitude: Double){
        self.Location?.latitude = latitude
        self.Location?.longitude = longitude
    }
}
