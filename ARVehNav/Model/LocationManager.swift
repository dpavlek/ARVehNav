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
    
    func getPosition() -> (Location: CLLocationCoordinate2D, Altitude: Double) {
        let curCoordinates = CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        let altitude = (locationManager.location?.altitude)!
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
        return currentLocation.DistanceTo(latitudeTo: destinationLocation.latitude, longitudeTo: destinationLocation.longitude)
    }
    
    func getAltitude(destination: CLLocationCoordinate2D, onCompletion: @escaping ((Double) -> Void)) {
        if let currentAltitude = locationManager.location?.altitude {
            var altitude = currentAltitude - 2
            Alamofire.request(Constants.getElevation(coordinates: destination)).responseJSON { response in
                switch response.result {
                    
                case .success(let data):
                    let response = JSON(data)
                    altitude = response["elevationProfile"][0]["height"].doubleValue
                    onCompletion(altitude)
                    
                case .failure(let error):
                    print(error)
                    onCompletion(altitude)
                }
            }
        }
    }
    
    func getDirection(previous: CLLocationCoordinate2D, current: CLLocationCoordinate2D, next: CLLocationCoordinate2D) -> Bool {
        let currentNew = CLLocationCoordinate2D(latitude: current.latitude - previous.latitude, longitude: current.longitude - previous.longitude)
        let nextNew = CLLocationCoordinate2D(latitude: next.latitude - previous.latitude, longitude: next.longitude - previous.longitude)
        if currentNew.latitude * nextNew.longitude > currentNew.longitude * nextNew.latitude {
            return true
        } else {
            return false
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
