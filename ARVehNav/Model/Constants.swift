//
//  Constants.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 01/05/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase

struct Constants {

    static let elevationURL = "https://open.mapquestapi.com/elevation/v1/profile?key=fmbWHqXFXSOKUyC9Lst1apAEGqGkyJUS&shapeFormat=raw&latLngCollection="

    static func getElevation(coordinates: CLLocationCoordinate2D) -> URL {
        let tempurl = elevationURL.description + "\(coordinates.latitude),\(coordinates.longitude)"
        let url = URL(string: tempurl)
        return url!
    }
}
