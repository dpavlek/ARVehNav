//
//  Item.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 16/03/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import Foundation
import CoreLocation
import Firebase

struct Item {
    let coordinates: (latitude: Double, longitude: Double)
    let name: String
    let description: String
    let dateAdded: Date
    let height: Double
    let itemID: String
}

class ItemManager {
    var items: [Item] = []
    
    func addItemToDatabase(itemToAdd: Item) {
        guard let userEmail = Auth.auth().currentUser?.uid else {
            print("No user id found")
            return
        }
        let ref = Constants.Refs.databaseItems.child(userEmail).childByAutoId()
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "CET")
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let itemDateString = dateFormatter.string(from: itemToAdd.dateAdded)
        
        let message = [
            "name": itemToAdd.name,
            "latitude": itemToAdd.coordinates.latitude.description,
            "longitude": itemToAdd.coordinates.longitude.description,
            "description": itemToAdd.description,
            "height":itemToAdd.height.description,
            "datetime": itemDateString
        ]
        
        ref.setValue(message)
    }
    
    func getItems(onCompletion: @escaping ((Bool) -> Void)) {
        guard let userEmail = Auth.auth().currentUser?.uid else {
            print("No user id found")
            return
        }
        let query = Constants.Refs.databaseItems.child(userEmail).queryLimited(toLast: 10)
        print(query.debugDescription)
        
        DispatchQueue.global().async {
            _ = query.observe(.childAdded, with: { [weak self] snapshot in
                if let data = snapshot.value as? [String: String],
                    let dateAdded = data["datetime"],
                    let description = data["description"],
                    let latitude = data["latitude"],
                    let longitude = data["longitude"],
                    let height = data["height"],
                    let name = data["name"] {
                    let itemID = snapshot.key
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm"
                    DispatchQueue.main.async {
                        if let dateFormatted = formatter.date(from: dateAdded) {
                            let item = Item(coordinates: (latitude: Double(latitude)!, longitude: Double(longitude)!), name: name, description: description, dateAdded: dateFormatted, height: Double(height)!, itemID: itemID)
                            self?.items.append(item)
                            onCompletion(true)
                        }
                    }
                }
            })
        }
    }
    
    func removeItem(itemID: String, onCompletion: @escaping ((Bool) -> Void)) {
        guard let userEmail = Auth.auth().currentUser?.uid else {
            print("No user id found")
            return
        }
        _ = Constants.Refs.databaseItems.child(userEmail).child(itemID).removeValue(completionBlock: { [weak self] Error, _ in
            if Error != nil {
                onCompletion(false)
            } else {
                if let items = self?.items.enumerated() {
                    for (index, item) in items where item.itemID == itemID {
                        self?.items.remove(at: index)
                    }
                }
                onCompletion(true)
            }
        })
    }
    
    func getCount() -> Int {
        return items.count
    }
}
