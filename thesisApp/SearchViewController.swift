//
//  SearchViewController.swift
//  thesisApp
//
//  Created by Bambam on 7/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import CoreLocation

extension UISearchBar {
    func getTextField() -> UITextField? { return value(forKey: "searchField") as? UITextField }
    func setTextField(color: UIColor) {
        guard let textField = getTextField() else { return }
            switch searchBarStyle {
            case .minimal:
                textField.layer.backgroundColor = color.cgColor
                textField.layer.cornerRadius = 6
            case .prominent, .default: textField.backgroundColor = color
            @unknown default: break
        }
    }
}

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {

    @IBOutlet weak var cafetable: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    let db = Firestore.firestore()
    var cafeArray = [CafeData]()
    var currentCafeArray = [CafeData]() //update table
    let getData = GetData()
    var from = ""
    var vSpinner : UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
        
        //ซ่อน tab bar
        setupSearchBar()
        getCafeData()
        hideKeyboard()
        
        cafetable.dataSource = self
        cafetable.delegate = self
        
        if from == "ใกล้ฉัน" {
            navigationItem.title = from
        }
        else if from == "ร้านยอดนิยม" {
            navigationItem.title = from
        }
        else {
            searchBar.becomeFirstResponder()
        }
        
//        setupLeftBarButtomItem()
        
//        UINavigationBar.appearance().shadowImage = UIImage()
//        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.barTintColor = .white
    }

    override func viewWillDisappear(_ animated: Bool){
        navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        navigationController?.navigationBar.setBackgroundImage(UIColor.clear.as1ptImage(), for: .default)
        self.navigationController?.navigationBar.barTintColor = .white
    }
    
    private func setupSearchBar() {
        //ทำให้ search bar มี bottom line
        searchBar.layer.shadowColor = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).cgColor
        searchBar.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        searchBar.layer.shadowOpacity = 1.0
        searchBar.layer.shadowRadius = 0.0
        searchBar.backgroundColor = .white
        searchBar[keyPath: \.searchTextField].font = UIFont(name: "Helvetica Neue", size: 16)
        searchBar.placeholder = "ค้นหาร้านคาเฟ่, ย่าน, หมวดหมู่"
        searchBar.backgroundImage = UIImage() //ทำให้ไม่มีขอบ
//        searchBar.setTextField(color: UIColor.white)
        searchBar.delegate = self
    }
    
    func setupLeftBarButtomItem() {
        let backButton = UIButton()
        backButton.setImage(UIImage(named: "back_white.png"), for: .normal)
        backButton.addTarget(self, action: #selector(backToPrevious), for: .touchUpInside)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 28)
        
        let menuBarItem = UIBarButtonItem(customView: backButton)
        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 40)
        let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 20)
        currWidth?.isActive = true
        currHeight?.isActive = true
    
        navigationItem.leftBarButtonItem = menuBarItem
    }
    
    @objc func gobackToPrevious() {
        performSegueToReturnBack()
    }
    
    func getCafeData() {
        loading(self.view)
        db.collection("cafe").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.cafeArray.removeAll()
            self.currentCafeArray.removeAll()
            for document in documents {
                if document.get("cafename_th") != nil && document.get("area_th") != nil && document.get("area_en") != nil && document.get("type") != nil && document.get("rating") != nil && document.get("ll_location") != nil {
                    let documentData = document.data()
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
                    
                    let (userLocationX, userLocationY) = self.currentLocation()
                    let rawDistance = self.calculateDistance(userLocationX: userLocationX, userLocationY: userLocationY, cafeLocationX: latitude, cafeLocationY: longitude)
                        print("\(cafename_en): \(rawDistance)")
                        
                    self.cafeArray.append(CafeData(cafe_id: cafe_id, cafename_en: cafename_en, cafename_th: cafename_th, style: style, area_en: area_en, area_th: area_th, imageURL: "", rating: rating1, rawDistance: rawDistance, reviewTotal: 0))
                }
            }
            let dispatch = DispatchGroup()
            self.getCoverImage(allId: self.cafeArray, dispatch: dispatch){ (arr) in
                dispatch.notify(queue: .main, execute: {
                    self.getReviewTotal(allId: arr, dispatch: dispatch){ (final) in
                        dispatch.notify(queue: .main, execute: {
                            if self.from == "ร้านยอดนิยม" {
                                self.currentCafeArray = final.sorted { (a, b) -> Bool in
                                    if a.reviewTotal > b.reviewTotal {
                                        return true
                                    }
                                    if a.rating > b.rating {
                                        return true
                                    }
                                    return false
                                }
                            }
                            else { //จากหน้า search
                                self.currentCafeArray = final.sorted { $0.rawDistance < $1.rawDistance }
                            }
                            self.removeLoading()
                            self.cafetable.reloadData()
                        })
                    }
                })
            }
        }
    }
    
    func getCoverImage(allId: [CafeData], dispatch:DispatchGroup, completed: @escaping ([CafeData]) -> Void) {
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
    
    func getReviewTotal(allId: [CafeData], dispatch:DispatchGroup, completed: @escaping ([CafeData]) -> Void) {
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
    
    //table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentCafeArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? SearchCell else {
            return UITableViewCell()
        }
        let cafe = currentCafeArray[indexPath.row]
        let name = "\(cafe.cafename_en) \(cafe.cafename_th)"
        
        //show info on table view
        cell.nameLabel.text = name
        cell.styleLabel.text = cafe.style
        cell.areaLabel.text = cafe.area_th
        cell.reviewTotalLabel.text = "\(cafe.reviewTotal) รีวิว"
        
        //แปลง distance ให้มีหน่วย km, m
        let distance = changeDistanceToString(rawDistance: cafe.rawDistance)
        cell.distanceLabel.text = distance
        cell.ratingLabel.text = "\(cafe.rating)"
        
        //get image from storage
        getData.getImage(imageURL: cafe.imageURL, imageView: cell.cafeImage)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cafeDetailVC = storyboard?.instantiateViewController(withIdentifier: "CafeDetail") as! CafeDetailViewController
        self.navigationController?.pushViewController(cafeDetailVC, animated: true)
        let cafe : CafeData
        cafe = currentCafeArray[indexPath.row]
        cafeDetailVC.cafeData = cafe
    }
    
    //search bar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard !searchText.isEmpty else {
            if from == "ร้านยอดนิยม" {
                self.currentCafeArray = cafeArray.sorted { (a, b) -> Bool in
                    if a.reviewTotal > b.reviewTotal {
                        return true
                    }
                    if a.rating > b.rating {
                        return true
                    }
                    return false
                }
            }
            else {
                currentCafeArray = cafeArray.sorted { $0.rawDistance < $1.rawDistance }
            }
            cafetable.reloadData()
            return
        }
        currentCafeArray = cafeArray.filter({ cafe -> Bool in
            cafe.cafename_en.lowercased().contains(searchText.lowercased()) || cafe.cafename_th.contains(searchText) ||
                cafe.area_en.lowercased().contains(searchText.lowercased()) || cafe.area_th.lowercased().contains(searchText.lowercased()) || cafe.style.lowercased().contains(searchText.lowercased())
        })
        cafetable.reloadData()
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        guard
//        segue.identifier == "showCafeDetailSegue",
//        let indexPath = cafetable.indexPathForSelectedRow,
//        let cafedetailVC = segue.destination as? CafeDetailViewController else { return }
//        let cafe : CafeData
//        cafe = cafeArray[indexPath.row]
//        
//        let name = "\(cafe.cafename_en) \(cafe.cafename_th)"
//        cafedetailVC.cafeData = cafe
//        cafedetailVC.cafeName = name
//    }
    
    func createData() {
        var ref: DocumentReference? = nil
        ref = db.collection("cafe").addDocument(data: [
            "cafename_en": "Daydream Believer",
            "cafename_th": "",
            "style": "ร้านอาหารและคาเฟ่",
            "area" : "อารีย์"
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
}

extension SearchViewController {
    
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


