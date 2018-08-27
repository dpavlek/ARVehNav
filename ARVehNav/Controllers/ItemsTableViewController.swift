//
//  ItemsTableViewController.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 26/07/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import UIKit
import MapKit

class ItemsTableViewController: UITableViewController {
    
    private let itemManager = ItemManager()
    private let loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingIndicator.center = CGPoint(x: view.bounds.size.width / 2, y: view.bounds.size.height / 3)
        loadingIndicator.color = UIColor.blue
        loadingIndicator.hidesWhenStopped = true
        tableView.tableFooterView = UIView()
        
        view.addSubview(loadingIndicator)
        tableView.separatorColor = UIColor.clear
        
        loadingIndicator.startAnimating()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        itemManager.getItems { [weak self] _ in
            self?.tableView.separatorColor = UIColor.lightGray
            self?.tableView.reloadData()
            self?.loadingIndicator.stopAnimating()
            print("Items got")
        }
        
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableCell", for: indexPath) as? ItemTableViewCell else {
            fatalError("Cell is not ItemTableCell")
        }
        
        let coordinates = CLLocationCoordinate2DMake(itemManager.items[indexPath.row].coordinates.latitude, itemManager.items[indexPath.row].coordinates.longitude)
        let pinPoint = MKPointAnnotation()
        pinPoint.coordinate = coordinates
        cell.mapView.addAnnotation(pinPoint)
        
        var region = MKCoordinateRegion()
        region.center = coordinates
        region.span.latitudeDelta = 0.002
        region.span.longitudeDelta = 0.002
        cell.mapView.setRegion(region, animated: false)
        
        cell.nameLabel.text = itemManager.items[indexPath.row].name
        cell.descLabel.text = itemManager.items[indexPath.row].description
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemManager.getCount()
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCellEditingStyle.delete {
            let itemID = itemManager.items[indexPath.row].itemID
            itemManager.removeItem(itemID: itemID, onCompletion: { [weak self] _ in
               self?.tableView.reloadData()
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showItemOnAr" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let controller = segue.destination as? ARViewController
                let item = itemManager.items[indexPath.row]
                controller?.destinationCoordinates.latitude = item.coordinates.latitude
                controller?.destinationCoordinates.longitude = item.coordinates.longitude
                controller?.itemAltitude = item.height
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
    }
    
}
