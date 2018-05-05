//
//  Route.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 01/05/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import CoreLocation
import SwiftyJSON

class Route {
    var points = [Item]()

    init?(json: [String: Any]) {
        let json = JSON(json)

        for (_, route) in json["routes"] {
            for (_, leg) in route["legs"] {
                for (_, step) in leg["steps"] {
                    for (_, intersection) in step["intersections"] {
                        let latitude = intersection["location"][0].doubleValue
                        let longitude = intersection["location"][1].doubleValue
                        let point = Item(Location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                        points.append(point)
                    }
                }
            }
        }
    }
}
