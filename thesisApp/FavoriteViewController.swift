//
//  FavoriteViewController.swift
//  thesisApp
//
//  Created by Bambam on 4/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

struct FavoriteData {
    var cafe_id: String
    var cafename_en: String
    var cafename_th: String
    var type: String
    var area_th: String
    var area_en : String
    var imageURL: String
    var rating: Float
    var reviewTotal: Int
    var rawDistance: Double
    var createdate: Timestamp
}

class FavoriteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var favoriteTable: UITableView!
    @IBOutlet weak var noFavoriteImage: UIImageView!
    @IBOutlet weak var noFavoriteLabel: UILabel!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    
    let db = Firestore.firestore()
    let callFunc = GetData()
    var favCafeArray = [FavoriteData]()
    var cafeArray = [CafeData]()
    var vSpinner: UIView?
    var from = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        navigationController?.navigationBar.setBackgroundImage(UIColor.clear.as1ptImage(), for: .default)
        navigationItem.title = "ที่บันทึกไว้"
        
        favoriteTable.dataSource = self
        favoriteTable.delegate = self
        loginButton.layer.cornerRadius = 5
        
        if Auth.auth().currentUser != nil {
            loginView.isHidden = true
            getUserFavoriteCafe()
        } else {
            loginView.isHidden = false
            loginButton.addTarget(self, action: #selector(openVC), for: .touchUpInside)
        }
        
        if from == "me" {
            setupNavigationBarItems()
        }
    }
    
    @objc func openVC() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
        vc.from = "FavoriteVC"
        self.present(vc, animated: true, completion: nil)
    }
    
    func getUserFavoriteCafe() {
        loading(self.view)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("favorite").whereField("uid", isEqualTo: uid).addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.favCafeArray.removeAll()
            for document in documents {
                let cafe_id = document.get("cafe_id") as! String
                if let createdate = document.get("createdate") as? Timestamp {
                    self.favCafeArray.append(FavoriteData(cafe_id: cafe_id, cafename_en: "", cafename_th: "", type: "", area_th: "", area_en: "", imageURL: "", rating: 0, reviewTotal: 0, rawDistance: 0, createdate: createdate))
                }
            }
            if self.favCafeArray.count > 0 {
                self.favoriteTable.isHidden = false
                let dispatch = DispatchGroup()
                self.getCafeData(allId: self.favCafeArray, dispatch: dispatch){(array) in
                    dispatch.notify(queue: .main, execute: {
                        self.getCoverImage(allId: array, dispatch: dispatch){(arr) in
                            dispatch.notify(queue: .main, execute: {
                                self.getReviewTotal(allId: arr, dispatch: dispatch){ (final) in
                                    dispatch.notify(queue: .main, execute: {
                                        self.favCafeArray.removeAll()
                                        self.favCafeArray = final.sorted { $0.createdate.dateValue() > $1.createdate.dateValue() }
                                        self.removeLoading()
                                        self.favoriteTable.reloadData()
                                    })
                                }
                            })
                        }
                    })
                }
            }
            else {
                self.removeLoading()
                self.favoriteTable.isHidden = true
            }
        }
    }
    
    func getCafeData(allId: [FavoriteData], dispatch:DispatchGroup, completed: @escaping ([FavoriteData]) -> Void) {
        let arrayLength = allId.count
        var array = allId
        for n in 0..<arrayLength {
            let id = array[n].cafe_id
            let cafeRef = self.db.collection("cafe").document(id)
            dispatch.enter()
            cafeRef.getDocument { (doc, err) in
                if let doc = doc, doc.exists {
                    let cafename_en = doc.get("cafename_en") as! String
                    let cafename_th = doc.get("cafename_th") as! String
                    let type = doc.get("type") as! String
                    let area_th = doc.get("area_th") as! String
                    let area_en = doc.get("area_en") as! String
                    let rating = doc.get("rating") as! Float
                    let ll_location = doc.get("ll_location") as! GeoPoint
                    let latitude = ll_location.latitude
                    let longitude = ll_location.longitude
                    
                    //calculate distance
                    let (userLocationX, userLocationY) = self.currentLocation()
                    let rawDistance = self.calculateDistance(userLocationX: userLocationX, userLocationY: userLocationY, cafeLocationX: latitude, cafeLocationY: longitude)
                    
                    array[n].cafename_en = cafename_en
                    array[n].cafename_th = cafename_th
                    array[n].type = type
                    array[n].area_th = area_th
                    array[n].area_en = area_en
                    array[n].rating = rating
                    array[n].rawDistance = rawDistance
                } else {
                    print("CafeRef's document does not exist")
                }
                dispatch.leave()
            }
        }
        dispatch.notify(queue: .main, execute: {
            completed(array)
        })
    }
    
    func getCoverImage(allId: [FavoriteData], dispatch:DispatchGroup, completed: @escaping ([FavoriteData]) -> Void) {
        let arrayLength = allId.count
        var array = allId
        for n in 0..<arrayLength {
            let id = array[n].cafe_id
            let cafeRef = self.db.collection("cafe_image").document(id)
            dispatch.enter()
            cafeRef.getDocument { (doc, err) in
                if let doc = doc, doc.exists {
                    let imageURL = doc.get("cafe_cover") as! String
                    array[n].imageURL = imageURL
                } else {
                    print("CafeImage's document does not exist")
                }
                dispatch.leave()
            }
        }
        dispatch.notify(queue: .main, execute: {
            completed(array)
        })
    }
    
    func getReviewTotal(allId: [FavoriteData], dispatch:DispatchGroup, completed: @escaping ([FavoriteData]) -> Void) {
        let arrayLength = allId.count
        var array = allId
        for n in 0..<arrayLength {
            let id = array[n].cafe_id
            let reviewRef = self.db.collection("review").whereField("cafe_id", isEqualTo: id)
            dispatch.enter()
            reviewRef.getDocuments { (snapshot, error) in
                if error == nil && snapshot != nil {
                    let reviewTotal = snapshot!.documents.count
                    array[n].reviewTotal = reviewTotal
                }
                dispatch.leave()
            }
        }
        dispatch.notify(queue: .main, execute: {
            completed(array)
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return favCafeArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath) as? FavoriteCell else {
            return UITableViewCell()
        }
        let fav = favCafeArray[indexPath.row]
        let name = "\(fav.cafename_en) \(fav.cafename_th)"
        cell.nameLabel.text = name
        cell.areaLabel.text = fav.area_th
        cell.genreLabel.text = fav.type
        cell.ratingLabel.text = "\(fav.rating)"
        cell.reviewTotalLabel.text = "\(fav.reviewTotal) รีวิว"
        
        
        let distance = changeDistanceToString(rawDistance: fav.rawDistance)
        cell.distanceLabel.text = distance
        
        cell.favoriteButton.setImage(UIImage(named: "bookmark2.png"), for: .normal)
        callFunc.getImage(imageURL: fav.imageURL, imageView: cell.cafeImage)
        cell.data = fav
        
        //set selected background view cell
        let bgColorView = UIView()
        bgColorView.backgroundColor = .white
        cell.selectedBackgroundView = bgColorView
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cafeDetailVC = storyboard?.instantiateViewController(withIdentifier: "CafeDetail") as! CafeDetailViewController
        let fav = favCafeArray[indexPath.row]
        let data = CafeData(cafe_id: fav.cafe_id, cafename_en: fav.cafename_en, cafename_th: fav.cafename_th, style: fav.type, area_en: fav.area_en, area_th: fav.area_th, imageURL: fav.imageURL, rating: fav.rating, rawDistance: fav.rawDistance, reviewTotal: fav.reviewTotal)
        cafeDetailVC.cafeData = data
        self.navigationController?.pushViewController(cafeDetailVC, animated: true)
    }
}

extension FavoriteViewController {
    
    func loading(_ uiView: UIView) {
        var loadingView: UIView = UIView()
        loadingView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        loadingView.center = self.view.center
        loadingView.backgroundColor = UIColor.init(red: 240/255, green: 240/255, blue: 241/255, alpha: 1)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10

        var activity: UIActivityIndicatorView = UIActivityIndicatorView()
        activity.frame = CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)
        activity.style = UIActivityIndicatorView.Style.large
        activity.center = CGPoint(x: loadingView.frame.size.width / 2, y: loadingView.frame.size.height / 2)
        
        DispatchQueue.main.async {
            loadingView.addSubview(activity)
            uiView.addSubview(loadingView)
        }
        vSpinner = loadingView
        activity.startAnimating()
    }
    
    func removeLoading() {
        DispatchQueue.main.async {
            self.vSpinner?.removeFromSuperview()
            self.vSpinner = nil
        }
    }
}
