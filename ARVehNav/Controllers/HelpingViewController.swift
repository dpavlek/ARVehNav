//
//  HelpingViewController.swift
//  ARVehNav
//
//  Created by Daniel Pavlekovic on 25/07/2018.
//  Copyright © 2018 Daniel Pavlekovic. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class HelpingViewController: UIViewController, GIDSignInUIDelegate {

    @IBOutlet weak var signInLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().uiDelegate = self
        let firebaseAuth = Auth.auth()
        if(firebaseAuth.currentUser == nil){
            signIn()
            signInLabel.text = NSLocalizedString("signedIn", comment: "Signed In!")
        }
        else{
            signInLabel.text = NSLocalizedString("signedOut", comment: "Signed Out")
            signOut()
        }
    }
    
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    func signIn(){
        GIDSignIn.sharedInstance().signIn()
    }
    
    func signOut(){
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            signInLabel.text = signOutError.localizedDescription
            print("Error signing out: %@", signOutError.localizedDescription)
        }
    }

}
