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
        
//        let db = Firestore.firestore()
//        var n = 0
//
//        db.collection("cafe").getDocuments() { (querySnapshot, err) in
//            if let err = err {
//                print("Error getting documents: \(err)")
//            } else {
//                for document in querySnapshot!.documents {
//                    let cafe_id = document.get("cafe_id") as! String
//                    db.collection("cafe").document(cafe_id).updateData([
//                        "onlinePayment": true
//                    ]) { err in
//                        if let err = err {
//                            print("Error updating document: \(err)")
//                        } else {
//                            print("Document successfully updated")
//                            n+=1
//                            print(n)
//                        }
//                    }
//                }
//            }
//        }
        
        
        //การเข้าถึงโลเคชั่น
//        let status = CLLocationManager.authorizationStatus()
//
//        switch status {
//
//        case .notDetermined:
//                locationManager.requestWhenInUseAuthorization()
//                return
//
//        case .denied, .restricted:
//            let alert = UIAlertController(title: "Location Services disabled", message: "Please enable Location Services in Settings", preferredStyle: .alert)
//            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
//            alert.addAction(okAction)
//
//            present(alert, animated: true, completion: nil)
//            return
//
//        case .authorizedAlways, .authorizedWhenInUse:
//            break
//
//        }
//        locationManager.delegate = self
//        locationManager.startUpdatingLocation()
        
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

