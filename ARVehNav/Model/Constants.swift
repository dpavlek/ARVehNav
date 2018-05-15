//
//  Constants.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 01/05/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import CoreLocation

struct Constants {

    static let osrmCore = "https://router.project-osrm.org/route/v1/driving/"

    static func osrmUrl(origin: CLLocationCoordinate2D, goal: CLLocationCoordinate2D) -> URL {
        let tempurl = osrmCore + "\(origin.longitude),\(origin.latitude);\(goal.longitude),\(goal.latitude)?steps=true&overview=false"
        return URL(string: tempurl)!
    }
}
