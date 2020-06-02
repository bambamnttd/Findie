//
//  AllCafeViewController.swift
//  thesisApp
//
//  Created by Bambam on 29/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class AllCafeViewController: UIViewController {
    
    @IBOutlet weak var cafetable: UITableView!
    
    let db = Firestore.firestore()
    var category = String()
    var cafeArray = [CafeData]()
    var currentCafeArray = [CafeData]()
    var promotionArray = [PromotionData]()
    let getData = GetData()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cafetable.dataSource = self
        cafetable.delegate = self
        setupNavigationBarItems()
        
        print(category)
        getCafeData(category: category)
        
        if category == "ใกล้ฉัน" {
            navigationItem.title = category
        }
        else {
            navigationItem.title = category
        }
    }
    
    func getCafeData(category: String) {
        db.collection("cafe").getDocuments { (snapshot, error) in
            if error == nil && snapshot != nil {
                for document in snapshot!.documents {
                    if document.get("cafename_th") != nil && document.get("area_th") != nil && document.get("area_en") != nil && document.get("type") != nil && document.get("rating") != nil && document.get("ll_location") != nil {
                        let cafe_id = document.get("cafe_id") as! String
                        let cafename_en = document.get("cafename_en") as! String
                        let cafename_th = document.get("cafename_th") as! String
                        let style = document.get("type") as! String
                        let area_en = document.get("area_en") as! String
                        let area_th = document.get("area_th") as! String
                        let rating = document.get("rating") as! Float
                        let rating1 = Float(String(format: "%.1f", rating)) as! Float
                        
                        let ll_location = document.get("ll_location") as! GeoPoint
                        let latitude = ll_location.latitude
                        let longitude = ll_location.longitude
                        
                        //ดึง url รูป จาก firestore "cafe_image"
                        let data = self.db.collection("cafe_image").document(cafe_id)
                        data.getDocument { (document, err) in
                            if let document = document, document.exists {
                                if document.get("cafe_cover") != nil {
                                    let imageURL = document.get("cafe_cover") as! String
                                    if imageURL != "" {
                                            
                                        //calculate distance
                                        let (userLocationX, userLocationY) = self.currentLocation()
                                        let rawDistance = self.calculateDistance(userLocationX: userLocationX, userLocationY: userLocationY, cafeLocationX: latitude, cafeLocationY: longitude)
                                        print("\(cafename_en): \(rawDistance)")
                                        
                                        let data = self.db.collection("review").whereField("cafe_id", isEqualTo: cafe_id)
                                        data.getDocuments { (snapshot, error) in
                                            if error == nil && snapshot != nil {
                                                let reviewTotal = snapshot!.documents.count
                                                self.cafeArray.append(CafeData(cafe_id: cafe_id, cafename_en: cafename_en, cafename_th: cafename_th, style: style, area_en: area_en, area_th: area_th, imageURL: imageURL, rating: rating1, rawDistance: rawDistance, reviewTotal: reviewTotal))
                                                
                                                if category == "ใกล้ฉัน" {
                                                    self.currentCafeArray = self.cafeArray.sorted { $0.rawDistance < $1.rawDistance }
                                                }
                                                else {
                                                    self.currentCafeArray = self.cafeArray.sorted { (a, b) -> Bool in
                                                        if a.reviewTotal > b.reviewTotal {
                                                            return true
                                                        }
                                                        if a.rating > b.rating {
                                                            return true
                                                        }
                                                        return false
                                                    }
                                                }
                                            }
                                            self.cafetable.reloadData()
                                        }
                                    }
                                }
                            }
                            else {
                                print("Document does not exist")
                            }
                        }
                    }
                }
            }
        }
    }
}

extension AllCafeViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentCafeArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AllCafeCell", for: indexPath) as? AllCafeCell else {
            return UITableViewCell()
        }
        let cafe = currentCafeArray[indexPath.row]
        cell.cafeNameLabel.text = cafe.cafename_en
        cell.genreLabel.text = cafe.style
        cell.areaLabel.text = cafe.area_th
        cell.ratingLabel.text = "\(cafe.rating)"
        cell.reviewTotalLabel.text = "\(cafe.reviewTotal) รีวิว"
        getData.getImage(imageURL: cafe.imageURL, imageView: cell.cafeImage)
        let distance = changeDistanceToString(rawDistance: cafe.rawDistance)
        cell.distanceLabel.text = distance
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cafeDetailVC = storyboard?.instantiateViewController(withIdentifier: "CafeDetail") as! CafeDetailViewController
        self.navigationController?.pushViewController(cafeDetailVC, animated: true)
        let cafe : CafeData
        cafe = currentCafeArray[indexPath.row]
        cafeDetailVC.cafeData = cafe
    }
    
}
