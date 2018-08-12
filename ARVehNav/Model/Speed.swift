//
//  Speed.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 02/08/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON
import SWXMLHash

class SpeedManager
{
    func getLocationID(location: CLLocationCoordinate2D, onCompletion: @escaping (Int) -> Void)
    {
        Alamofire.request("https://nominatim.openstreetmap.org/reverse?format=json&lat=\(location.latitude)&lon=\(location.longitude)&zoom=17&addressdetails=0").responseJSON
        { response in
            switch response.result {

            case .success(let data):
                let response = JSON(data)
                let osmID = response["osm_id"].intValue
                print("OSM_ID: \(osmID)")
                onCompletion(osmID)

            case .failure(let error):
                print(error)
                onCompletion(1)
            }
        }
    }

    func getSpeedLimit(osmID: Int, onCompletion: @escaping (Int) -> Void)
    {
        Alamofire.request("https://www.openstreetmap.org/api/0.6/way/\(osmID)").responseData
        { [weak self] response in
            if let data = response.data
            {
                let xml = SWXMLHash.parse(data)
                if let speed = try? xml["osm"]["way"]["tag"].withAttribute("k", "maxspeed").element?.attribute(by: "v")?.text
                {
                    print(speed!)
                    onCompletion(Int(speed!)!)
                }
                else if let roadType = try? xml["osm"]["way"]["tag"].withAttribute("k", "highway").element?.attribute(by: "v")?.text
                {
                    print(roadType)
                    let speed = self?.speedForType(type: roadType!)
                    print(speed!)
                    onCompletion(speed!)
                }
                else
                {
                    print("default speed")
                    onCompletion(50)
                }
            }
        }
    }

    func speedForType(type: String) -> Int
    {
        switch type {
        case("highway"): // autocesta
            return 130
        case("trunk"): // brza cesta
            return 110
        case("primary"): // glavna cesta
            return 90
        case("pedestrian"): // pješačka zona
            return 0
        case("living_street"): // zona smirenog prometa
            return 10
        default:
            return 50
        }
    }
}
