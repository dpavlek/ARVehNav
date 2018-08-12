//
//  MKMultiPoint+Coordinates.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 06/08/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import MapKit

public extension MKMultiPoint{
    var coordinates: [CLLocationCoordinate2D]{
        var rCoords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&rCoords, range: NSMakeRange(0, pointCount))
        return rCoords
    }
}
