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
    static let elevationURL = "https://open.mapquestapi.com/elevation/v1/profile?key=fmbWHqXFXSOKUyC9Lst1apAEGqGkyJUS&shapeFormat=raw&latLngCollection="

    static func osrmUrl(origin: CLLocationCoordinate2D, goal: CLLocationCoordinate2D) -> URL {
        let tempurl = osrmCore + "\(origin.longitude),\(origin.latitude);\(goal.longitude),\(goal.latitude)?steps=true&overview=false"
        return URL(string: tempurl)!
    }

    static func getElevation(coordinates: CLLocationCoordinate2D) -> URL {
        let tempurl = elevationURL.description + "\(coordinates.latitude),\(coordinates.longitude)"
        let url = URL(string: tempurl)
        return url!
    }
}
