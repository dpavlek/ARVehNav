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

class LocationManager {
    let locationManager = CLLocationManager()
    
    init() {
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
            locationManager.startUpdatingLocation()
            locationManager.delegate = self as? CLLocationManagerDelegate
        }
        
        if CLLocationManager.headingAvailable() {
            locationManager.headingFilter = 1
            locationManager.startUpdatingHeading()
            locationManager.delegate = self as? CLLocationManagerDelegate
        }
    }
    
    func getPosition() -> (Location: CLLocationCoordinate2D, Altitude: Double) {
        let curCoordinates = CLLocationCoordinate2D(latitude: (locationManager.location?.coordinate.latitude)!, longitude: (locationManager.location?.coordinate.longitude)!)
        let altitude = (locationManager.location?.altitude)!
        return (curCoordinates, altitude)
    }
    
    func getDistance(currentLocation: CLLocationCoordinate2D, destinationLocation: CLLocationCoordinate2D) -> (lat: Double, long: Double) {
        var distance: (lat: Double, long: Double)
        distance.long = destinationLocation.DistanceTo(latitudeTo: destinationLocation.latitude, longitudeTo: currentLocation.longitude)
        distance.lat = destinationLocation.DistanceTo(latitudeTo: currentLocation.latitude, longitudeTo: destinationLocation.longitude)
        print(distance.lat, distance.long)
        return distance
    }
    
    func getAirDistance(currentLocation: CLLocationCoordinate2D, destinationLocation: CLLocationCoordinate2D) -> Double {
        return currentLocation.DistanceTo(latitudeTo: destinationLocation.latitude, longitudeTo: destinationLocation.longitude)
    }
    
    func getAltitude(currentAltitude: Double, destination: CLLocationCoordinate2D, onCompletion: @escaping ((Double) -> Void)) {
        var altitude = currentAltitude - 5
        Alamofire.request(Constants.getElevation(coordinates: destination)).responseJSON { response in
            switch response.result {
                
            case .success(let data):
                let response = JSON(data)
                altitude = response["elevationProfile"]["height"].doubleValue
                onCompletion(altitude)
                
            case .failure(let error):
                print(error)
                onCompletion(altitude)
            }
            
        }
    }
    
    func getAltitudeDiff(currentAltitude: Double, destinationAltitude: Double) -> Double {
        return destinationAltitude - currentAltitude
    }
    
}
