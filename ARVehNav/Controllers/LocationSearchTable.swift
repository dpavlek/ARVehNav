//
//  LocationSearchTable.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 25/07/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import UIKit
import MapKit

class LocationSearchTable:UITableViewController{
    
    var matchItems:[MKMapItem] = []
    var destinationMapView: MKMapView? = nil
    var handleMapSearchDelegate:handleMapSearch? = nil
    
    func getAddress(item: MKPlacemark)->String{
        var address = ""
        if let number = item.subThoroughfare {
            address += number.description
        }
        if let itemAddr = item.thoroughfare{
            address += " \(itemAddr.description)"
        }
        if let city = item.locality{
            address += ", \(city.description)"
        }
        if let region = item.administrativeArea{
            address += ", \(region.description)"
        }
        return address
    }
}

extension LocationSearchTable:UISearchResultsUpdating{
    func updateSearchResults(for searchController: UISearchController) {
        guard let destinationMapView = destinationMapView,
            let searchBarText = searchController.searchBar.text else {
                return
            }
        let req = MKLocalSearchRequest()
        req.naturalLanguageQuery = searchBarText
        req.region = destinationMapView.region
        let search = MKLocalSearch(request: req)
        search.start { [weak self] (data, err) in
            guard let data = data else{
                print(err?.localizedDescription)
                return
            }
            self?.matchItems = data.mapItems
            self?.tableView.reloadData()
        }
    }
}

extension LocationSearchTable{
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell") else{
            fatalError("Cell error")
        }
        let selected = matchItems[indexPath.row].placemark
        cell.textLabel?.text = selected.name
        cell.detailTextLabel?.text = getAddress(item: selected)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = matchItems[indexPath.row].placemark
        handleMapSearchDelegate?.dropPinZoom(place: selected)
        dismiss(animated: true, completion: nil)
    }
}
