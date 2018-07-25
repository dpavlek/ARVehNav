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
    
    @IBOutlet weak var signBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let firebaseAuth = Auth.auth()
        if (firebaseAuth.currentUser) == nil {
            signBtn.setTitle("Sign In With Google", for: .normal)
        } else {
            signBtn.setTitle("Sign Out", for: .normal)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
