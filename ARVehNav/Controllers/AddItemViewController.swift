//
//  AddItemViewController.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 31/07/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import UIKit
import CoreLocation

class AddItemViewController: UIViewController {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var descField: UITextView!
    
    var itemManager = ItemManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descField.layer.borderColor = UIColor.gray.cgColor
        descField.layer.borderWidth = 0.5
    }
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveItem(_ sender: Any) {
        addItemToDatabase { success in
            if success {
                print("Item added to database")
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                print("Failure to add to database") }
        }
    }
    
    func addItemToDatabase(onCompletion: @escaping (Bool) -> Void) {
        if let location = LocationManager.shared.getPosition().Location {
            if let altitude = LocationManager.shared.getPosition().Altitude {
                guard let name = nameField.text,
                    let description = descField.text,
                    !name.isEmpty, !description.isEmpty else {
                    onCompletion(false)
                    return
                }
                
                let itemToAdd = Item(coordinates: (latitude: location.latitude, longitude: location.longitude), name: nameField.text!, description: descField.text, dateAdded: Date(), height: altitude, itemID: "")
                
                itemManager.addItemToDatabase(itemToAdd: itemToAdd)
                onCompletion(true)
            }
            onCompletion(false)
        }
        onCompletion(false)
    }
}
