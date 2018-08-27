//
//  LocationManager.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 31/07/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    let locationManager = CLLocationManager()
    var locationList: [CLLocation] = []
    var heading: CLLocationDistance?
    
    private override init() {
        super.init()
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
            locationManager.delegate = self
        }
        
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
            locationManager.delegate = self
        }
    }
    
    func getPosition() -> (Location: CLLocationCoordinate2D?, Altitude: Double?) {
        var curCoordinates: CLLocationCoordinate2D? = nil
        if let location = locationManager.location{
            curCoordinates = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        }
        let altitude = (locationManager.location?.altitude)
        return (curCoordinates, altitude)
    }
    
    func getSpeed() -> Double {
        if let speed = locationManager.location?.speed {
            return speed
        } else {
            return -1
        }
    }
    
    func getDistanceTo(locationCoords: CLLocationCoordinate2D) -> CLLocationDistance? {
        let location = CLLocation(latitude: locationCoords.latitude, longitude: locationCoords.longitude)
        if let lastLocation = getLastLocation() {
            return lastLocation.distance(from: location)
        } else {
            return nil
        }
    }
    
    func getDistance(currentLocation: CLLocationCoordinate2D, destinationLocation: CLLocationCoordinate2D) -> (lat: Double, long: Double) {
        var distance: (lat: Double, long: Double)
        distance.long = destinationLocation.DistanceTo(latitudeTo: destinationLocation.latitude, longitudeTo: currentLocation.longitude)
        distance.lat = destinationLocation.DistanceTo(latitudeTo: currentLocation.latitude, longitudeTo: destinationLocation.longitude)
        return distance
    }
    
    func getAirDistance(currentLocation: CLLocationCoordinate2D, destinationLocation: CLLocationCoordinate2D) -> Double {
            let R = 6378.137
            let distanceLat = destinationLocation.latitude * Double.pi / 180 - currentLocation.latitude * Double.pi / 180
            let distanceLong = destinationLocation.longitude * Double.pi / 180 - currentLocation.longitude * Double.pi / 180
            let a = sin(distanceLat / 2) * sin(distanceLat / 2) + cos(destinationLocation.latitude * Double.pi / 180) * cos(currentLocation.latitude * Double.pi / 180) * sin(distanceLong / 2) * sin(distanceLong / 2)
            let c = 2 * atan2(sqrt(a), sqrt(1 - a))
            let d = R * c
            return d * 1000
    }
    
    func getAltitude(destination: CLLocationCoordinate2D, onCompletion: @escaping ((Double) -> Void)) {
            var altitude: Double = -1
            Alamofire.request(Constants.getElevation(coordinates: destination)).responseJSON { response in
                switch response.result {
                    
                case .success(let data):
                    let response = JSON(data)
                    altitude = response["elevationProfile"][0]["height"].doubleValue
                    onCompletion(altitude)
                    
                case .failure(let error):
                    print("Alamofire: \(error)")
                    onCompletion(altitude)
                }
            }
    }
    
    enum turns{
        case left
        case right
        case straight
    }
    
    func getDirection(previous: CLLocationCoordinate2D, current: CLLocationCoordinate2D, next: CLLocationCoordinate2D) -> turns {
        let currentNew = CLLocationCoordinate2D(latitude: current.latitude - previous.latitude, longitude: current.longitude - previous.longitude)
        let nextNew = CLLocationCoordinate2D(latitude: next.latitude - previous.latitude, longitude: next.longitude - previous.longitude)
        if  abs(currentNew.latitude*nextNew.longitude - currentNew.longitude*nextNew.latitude)<0.0000001{
            return .straight
        }
        else if currentNew.latitude * nextNew.longitude > currentNew.longitude * nextNew.latitude {
            return .right
        } else {
            return .left
        }
    }
    
    func getAltitudeDiff(currentAltitude: Double, destinationAltitude: Double) -> Double {
        return destinationAltitude - currentAltitude
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationList = locations
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.trueHeading
    }
    
    func getLastLocation() -> CLLocation? {
        if let location = locationList.last {
            return location
        } else {
            return nil
        }
    }
    
}
