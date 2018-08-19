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
            signInLabel.text = "You have successfully signed in!"
        }
        else{
            signOut()
            signInLabel.text = "You have signed out!"
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    @IBAction func done(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
