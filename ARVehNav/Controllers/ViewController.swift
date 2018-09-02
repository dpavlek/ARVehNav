//
//  ViewController.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 26/02/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let location = LocationManager.shared.lastLocation
    }
    
}
