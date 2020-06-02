//
//  MapViewController.swift
//  thesisApp
//
//  Created by Bambam on 17/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var getDirectionButton: UIButton!
    
    var latitude = Double()
    var longitude = Double()
    var cafename_en = String()
    var cafe_id = String()
    let cafeDetailVC = CafeDetailViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = cafename_en
        getDirectionButton.layer.cornerRadius = 5
        setPinUsingMKPointAnnotation()
        getDirectionButton.addTarget(self, action: #selector(cafeDetailVC.openMaps), for: .touchUpInside)
        setupNavigationBarItems()
    }
    
    func setPinUsingMKPointAnnotation(){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        annotation.title = cafename_en
//        annotation.subtitle = "Device Location"
        mapView.addAnnotation(annotation)
        mapView.showsUserLocation = true
            
        let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
        mapView.setRegion(region, animated: true)
    }
    
    @objc func openMaps() {
        let locationName = cafename_en
        let appleMapsURL = URL(string: "http://maps.apple.com")!
        let googleMapsURL = URL(string: "comgooglemaps-x-callback://")!
        
        let dispatch = DispatchGroup()
        cafeDetailVC.getLatitudeAndLongitude(cafe_id: cafe_id, dispatch: dispatch){ (lat,long) in
            dispatch.notify(queue: .main, execute: {
                if UIApplication.shared.canOpenURL(appleMapsURL) && UIApplication.shared.canOpenURL(googleMapsURL) {
                    let optionMenu = UIAlertController(title: nil, message: "Open with", preferredStyle: .actionSheet)
                    
                     //Apple Maps
                    let appleMapsAction = UIAlertAction(title: "Apple Maps", style: .default) { (action) in
                        let latitude:CLLocationDegrees = lat
                        let longitude:CLLocationDegrees = long
                        
                        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
                        
                        let placemark = MKPlacemark(coordinate: coordinates)
                        let mapItem = MKMapItem(placemark: placemark)
                        mapItem.name = locationName
                        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
                    }
                    
                    //Google Maps
                    let googleMapsAction = UIAlertAction(title: "Google Maps", style: .default) { (action) in
                        if UIApplication.shared.canOpenURL(googleMapsURL) {
                            let directionsRequest = "comgooglemaps-x-callback://" +
                                "?daddr=\(lat),\(long)" + "&travelmode=driving&x-success=sourceapp://?resume=true&x-source=AirApp"
                            let directionsURL = URL(string: directionsRequest)!
                            UIApplication.shared.openURL(directionsURL)
                        }
                        else {
                            NSLog("Can't use comgooglemaps-x-callback:// on this device.")
                        }
                    }
                    optionMenu.addAction(appleMapsAction)
                    optionMenu.addAction(googleMapsAction)
                    
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                    optionMenu.addAction(cancelAction)
                        
                    self.present(optionMenu, animated: true, completion: nil)
                }
            })
        }
    }
}
