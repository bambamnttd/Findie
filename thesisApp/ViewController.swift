//
//  ViewController.swift
//  thesisApp
//
//  Created by Bambam on 4/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
 
class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()

    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    var from = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpButton()
        
        //ทำให้อยู่ตรงกลาง
        loginButton.center.x = self.view.center.x
        signupButton.center.x = self.view.center.x
        skipButton.center.x = self.view.center.x   
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let email = Auth.auth().currentUser {
            self.performSegue(withIdentifier: "toHomeScreen", sender: self)
        }
    }
    
    func setUpButton() {
        loginButton.layer.cornerRadius = 5
        signupButton.layer.borderWidth = 1
        signupButton.layer.borderColor = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).cgColor
        signupButton.layer.cornerRadius = 5
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.last {
            print("Current location: \(currentLocation)")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
}

