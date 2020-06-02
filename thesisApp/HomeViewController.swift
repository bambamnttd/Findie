//
//  HomeViewController.swift
//  thesisApp
//
//  Created by Bambam on 4/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import CoreLocation

extension HomeViewController: BookQueueDelegate {
    func bookSuccess(success: Bool) {
        self.success = success
    }
}

class HomeViewController: UIViewController {

    @IBOutlet weak var searchBar: UIButton!
    @IBOutlet weak var rewardButton: UIButton!
    @IBOutlet weak var promotionButton: UIButton!
    @IBOutlet weak var queueButton: UIButton!
    
    @IBOutlet weak var nearMeCollectionView: UICollectionView!
    @IBOutlet weak var nearMeCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var popularCafeCollectionView: UICollectionView!
    @IBOutlet weak var popularCafeCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var nearMeLabel: UILabel!
    @IBOutlet weak var popularCafeLabel: UILabel!
    @IBOutlet weak var moreButton1: UIButton!
    
    @IBOutlet weak var promotionCollectionView: UICollectionView!
    @IBOutlet weak var moreButton2: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var myscrollView: UIScrollView!
    
    let cellIdentifier = "NearMeCell"
    let cellIdentifier2 = "PromotionHomeCell"
    let headerId = "HeaderHome"
    let footerId = "FooterHome"
    let db = Firestore.firestore()
    var cafeArray = [CafeData]()
    var nearMeArray = [CafeData]()
    var popularArray = [CafeData]()
    var promotionArray = [PromotionData]()
    var currentNearMeArray = [CafeData]()
    var currentPopularArray = [CafeData]()
    var getData = GetData()
    var vSpinner : UIView?
    let redColor: UIColor = .init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1)
    let greyColor: UIColor = .init(red: 138/255, green: 138/255, blue: 142/255, alpha: 1)
    let blackColor: UIColor = .init(red: 49/255, green: 49/255, blue: 51/255, alpha: 1)
    let dispatch = DispatchGroup()
    var frame = CGRect(x: 0, y: 0, width: 0, height: 0)
    var success = false
    
    var timer = Timer()
    var counter = 0
    
    var locationManager: CLLocationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loading(self.view)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.tintColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 1)
        self.navigationController?.navigationBar.isTranslucent = true
        
        // Set the shadow color.
//        navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
//        navigationController?.navigationBar.setBackgroundImage(UIColor.clear.as1ptImage(), for: .default)
        setupSearchButtonOnNavbar()
        setUpSearchBarButton()
        setupCollectionView()
        setCategoryLabelTab()
        getCafeData()
        
        self.pageControl.currentPage = 0
        getPromotionData(dispatch: dispatch) {(array) in
            self.dispatch.notify(queue: .main, execute: {
                self.pageControl.numberOfPages = array.count
            })
        } 
        self.timer = Timer.scheduledTimer(timeInterval: 3.5, target: self, selector: #selector(self.changePromotionImage), userInfo: nil, repeats: true)
        
        searchBar.center.x = self.view.center.x
        
        searchBar.addTarget(self, action: #selector(openSearchVC), for: .touchUpInside)
        queueButton.addTarget(self, action: #selector(openQueueListVC), for: .touchUpInside)
        rewardButton.addTarget(self, action: #selector(openRewardListVC), for: .touchUpInside)
        promotionButton.addTarget(self, action: #selector(openPromotionVC), for: .touchUpInside)
        moreButton1.addTarget(self, action: #selector(clickMoreButton1), for: .touchUpInside)
        moreButton2.addTarget(self, action: #selector(clickMoreButton2), for: .touchUpInside)
        
        myscrollView.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("เข้าหรือไม่ \(success)")
        if success == true {
            //เปลี่ยนไป tab my queue
            self.tabBarController?.selectedIndex = 2
            let navVC = tabBarController?.viewControllers![2] as! UINavigationController
            let myQueueVC = navVC.topViewController as! MyQueueViewController
            myQueueVC.newQueue = success
            success = false
        }
    }
    
    @objc func openSearchVC() {
        let searchVC = storyboard?.instantiateViewController(withIdentifier: "SearchVC") as! SearchViewController
        self.navigationController?.pushViewController(searchVC, animated: true)
    }
    
    @objc func openQueueListVC() {
        let queueListVC = storyboard?.instantiateViewController(withIdentifier: "QueueListVC") as! QueueListViewController
        queueListVC.delegate = self
        self.navigationController?.pushViewController(queueListVC, animated: true)
    }
    
    @objc func openRewardListVC() {
        let rewardListVC = storyboard?.instantiateViewController(withIdentifier: "RewardListVC") as! RewardListViewController
        self.navigationController?.pushViewController(rewardListVC, animated: true)
    }
    
    @objc func openPromotionVC() {
        let promotionVC = storyboard?.instantiateViewController(withIdentifier: "PromotionVC") as! PromotionViewController
        self.navigationController?.pushViewController(promotionVC, animated: true)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
//        self.navigationController?.navigationBar.setBackgroundImage(UIColor.white.as1ptImage(), for: .default)
//        self.navigationController?.navigationBar.shadowImage = redColor.as1ptImage()
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.tintColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 1)
//        self.navigationController?.navigationBar.isTranslucent = true
//        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool){
        self.navigationController?.navigationBar.setBackgroundImage(UIColor.white.as1ptImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = redColor.as1ptImage()
       self.navigationController?.navigationBar.isTranslucent = false
    }
    
    ///คำสั่งที่ทำให้ความยาวของ collection view เท่ากับส่วน content
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        let height = nearMeCollectionView.collectionViewLayout.collectionViewContentSize.height
//        nearMeCollectionViewHeight.constant = height
//        print(height)
//        self.view.layoutIfNeeded()
//    }
    
    func setupSearchButtonOnNavbar() {
        let searchButton = UIButton()
        searchButton.setImage(UIImage(named: "search_red.png"), for: .normal)
        searchButton.addTarget(self, action: #selector(openSearchVC), for: .touchUpInside)
        searchButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let menuBarItem = UIBarButtonItem(customView: searchButton)
        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 20)
        let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 20)
        currWidth?.isActive = true
        currHeight?.isActive = true
    
        navigationItem.rightBarButtonItem = menuBarItem
    }
    
    func setUpSearchBarButton() {
        searchBar.layer.cornerRadius = 5
        searchBar.layer.shadowColor = UIColor.gray.cgColor
        searchBar.layer.shadowOffset = CGSize(width: 2, height: 2)
        searchBar.layer.shadowRadius = 3.5
        searchBar.layer.shadowOpacity = 0.4
        searchBar.setImage(UIImage(named: "search.png"), for: .normal)
        searchBar.imageEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 346)
        searchBar.setTitle("ค้นหาร้านคาเฟ่, ย่าน, หมวดหมู่", for: .normal)
        searchBar.titleEdgeInsets = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 0)
        //searchBar.addTarget(self, action: #selector(goToSearchVC), for: .touchUpInside)
    }
    
    func setupCollectionView() {
        popularCafeCollectionView.isHidden = false
        nearMeCollectionView.delegate = self
        nearMeCollectionView.dataSource = self
        let nib = UINib(nibName: "NearMeCell", bundle: nil)
        nearMeCollectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        nearMeCollectionView.backgroundColor = .white
        
        popularCafeCollectionView.isHidden = true
        popularCafeCollectionView.delegate = self
        popularCafeCollectionView.dataSource = self
        popularCafeCollectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
        popularCafeCollectionView.backgroundColor = .white
        
        promotionCollectionView.delegate = self
        promotionCollectionView.dataSource = self
        promotionCollectionView.backgroundColor = .white
    }
    
    @objc func tapNearMe() {
        if nearMeLabel.textColor == greyColor {
            nearMeLabel.textColor = blackColor
            nearMeLabel.buttomBorder(color: UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).cgColor)
            
            nearMeCollectionView.isHidden = false
            popularCafeCollectionView.isHidden = true
            
            popularCafeLabel.textColor = greyColor
            popularCafeLabel.buttomBorder(color: UIColor.white.cgColor)
        }
    }
    
    @objc func tapPopularCafe() {
        if popularCafeLabel.textColor == greyColor {
            popularCafeLabel.textColor = blackColor
            popularCafeLabel.buttomBorder(color: UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).cgColor)
            
            popularCafeCollectionView.isHidden = false
            nearMeCollectionView.isHidden = true
            
            nearMeLabel.textColor = greyColor
            nearMeLabel.buttomBorder(color: UIColor.white.cgColor)
        }
    }
    
    @objc func clickMoreButton1() {
        let searchVC = storyboard?.instantiateViewController(withIdentifier: "SearchVC") as! SearchViewController
        if nearMeLabel.textColor == blackColor {
            searchVC.from = "ใกล้ฉัน"
        }
        else {
            searchVC.from = "ร้านยอดนิยม"
        }
        self.navigationController?.pushViewController(searchVC, animated: true)
    }
    
    @objc func clickMoreButton2() {
        let promotionVC = storyboard?.instantiateViewController(withIdentifier: "PromotionVC") as! PromotionViewController
        self.navigationController?.pushViewController(promotionVC, animated: true)
    }
    
    func setCategoryLabelTab() {
        let nearMeTap = UITapGestureRecognizer(target: self, action: #selector(tapNearMe))
        let popularCafeTap = UITapGestureRecognizer(target: self, action: #selector(tapPopularCafe))
        
        nearMeLabel.textColor = blackColor
        nearMeLabel.buttomBorder(color: UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).cgColor)
        nearMeLabel.isUserInteractionEnabled = true
        nearMeLabel.addGestureRecognizer(nearMeTap)
        
        popularCafeLabel.textColor = greyColor
        popularCafeLabel.isUserInteractionEnabled = true
        popularCafeLabel.addGestureRecognizer(popularCafeTap)
    }
    
    @objc func changePromotionImage() {
        getPromotionData(dispatch: dispatch) {(array) in
            self.dispatch.notify(queue: .main, execute: {
                if self.counter < array.count {
                    let index = IndexPath.init(item: self.counter, section: 0)
                    self.promotionCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
                    self.pageControl.currentPage = self.counter
                    self.counter += 1
                }
                else {
                    self.counter = 0
                    let index = IndexPath.init(item: self.counter, section: 0)
                    self.promotionCollectionView.scrollToItem(at: index, at: .centeredHorizontally, animated: true)
                    self.pageControl.currentPage = self.counter
                    self.counter = 1
                }
            })
        }
    }
    
    func getCafeData() {
        db.collection("cafe").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.cafeArray.removeAll()
            self.nearMeArray.removeAll()
            self.popularArray.removeAll()
            self.currentNearMeArray.removeAll()
            self.currentPopularArray.removeAll()
            for document in documents {
                if document.get("cafename_th") != nil && document.get("area_th") != nil && document.get("area_en") != nil && document.get("type") != nil && document.get("rating") != nil && document.get("ll_location") != nil && document.get("cafe_id") != nil {
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
                        
                    self.cafeArray.append(CafeData(cafe_id: document.documentID, cafename_en: cafename_en, cafename_th: cafename_th, style: style, area_en: area_en, area_th: area_th, imageURL: "", rating: rating1, rawDistance: rawDistance, reviewTotal: 0))
                }
            }
            let dispatch = DispatchGroup()
            self.getCoverImage(allId: self.cafeArray, dispatch: dispatch){ (arr) in
                dispatch.notify(queue: .main, execute: {
                    self.getReviewTotal(allId: arr, dispatch: dispatch){ (final) in
                        dispatch.notify(queue: .main, execute: {
                            self.nearMeArray = final.sorted { $0.rawDistance < $1.rawDistance }
                            self.popularArray = final.sorted { (a, b) -> Bool in
                                if a.reviewTotal > b.reviewTotal {
                                    return true
                                }
                                if a.rating > b.rating {
                                    return true
                                }
                                return false
                            }
                            self.currentNearMeArray = Array(self.nearMeArray.prefix(4))
                            self.currentPopularArray = Array(self.popularArray.prefix(4))
                            self.removeLoading()
                            self.nearMeCollectionView.reloadData()
                            self.popularCafeCollectionView.reloadData()
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
                    array[n].imageURL = ""
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
    
    func getPromotionData(dispatch:DispatchGroup, completed: @escaping ([PromotionData]) -> Void) {
        let promotionRef = self.db.collection("promotion").order(by: "createdate", descending: true)
        promotionRef.getDocuments { (snapshot, error) in
            if error == nil && snapshot != nil {
                self.promotionArray.removeAll()
                for document in snapshot!.documents {
                    let promotion_id = document.get("promotion_id") as! String
                    let cafe_id = document.get("cafe_id") as! String
                    let promotion_topic = document.get("promotion_topic") as! String
                    let promotion_detail = document.get("promotion_detail") as! String
                    let startdate = document.get("startdate") as! Timestamp
                    let enddate = document.get("enddate") as! Timestamp
                    let promotion_imageURL = document.get("promotion_imageURL") as! String
                    self.promotionArray.append(PromotionData(promotion_id: promotion_id, cafe_id: cafe_id, cafename_en: "", promotion_topic: promotion_topic, promotion_detail: promotion_detail, startdate: startdate.dateValue(), enddate: enddate.dateValue() , promotion_imageURL: promotion_imageURL))
                }
                
                self.getCafename(allId: self.promotionArray, dispatch: dispatch){ (arr) in
                    dispatch.notify(queue: .main, execute: {
                        dispatch.enter()
                        self.promotionArray.removeAll()
                        self.promotionArray = arr
                        self.promotionCollectionView.reloadData()
                        dispatch.leave()
                    })
                }
            }
        }
        dispatch.notify(queue: .main, execute: {
            completed(self.promotionArray)
        })
    }
    
    func getCafename(allId: [PromotionData], dispatch:DispatchGroup, completed: @escaping ([PromotionData]) -> Void) {
        let arrayLength = allId.count
        var array = allId
        for n in 0..<arrayLength {
            let id = array[n].cafe_id
            let cafeRef = self.db.collection("cafe").document(id)
            dispatch.enter()
            cafeRef.getDocument { (doc, err) in
                if let doc = doc, doc.exists {
                    let cafename = doc.get("cafename_en") as! String
                    array[n].cafename_en = cafename
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
    
    ///เปลี่ยนให้ StatusBar เป็นตีมขาว หรือดำ
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent  //เปลี่ยนเป็นตีมขาว
    }
}

extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == myscrollView {
            var offset = myscrollView.contentOffset.y / 150
            print(offset)
            if offset > 1.4 {
                offset = 1
                let color = UIColor.init(red: 1, green: 1, blue: 1, alpha: offset)
                let navigationcolor = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: offset)
                self.navigationController?.navigationBar.tintColor = navigationcolor
                self.navigationController?.navigationBar.setBackgroundImage(color.as1ptImage(), for: .default)
//                self.navigationController?.navigationBar.backgroundColor = color
//                self.navigationController?.navigationBar.barTintColor = color
                self.navigationController?.navigationBar.shadowImage = redColor.as1ptImage()
//                  self.navigationController?.setNavigationBarHidden(false, animated: true)
//                self.navigationController?.setStatusBar(alpha: Float(offset))
            }
            else {
                let color = UIColor.init(red: 1, green: 1, blue: 1, alpha: offset)
                self.navigationController?.navigationBar.tintColor = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: offset)
//                self.navigationController?.navigationBar.backgroundColor = color
//                self.navigationController?.navigationBar.barTintColor = color
                self.navigationController?.navigationBar.setBackgroundImage(color.as1ptImage(), for: .default)
                    self.navigationController?.navigationBar.shadowImage = UIImage()
//                self.navigationController?.setNavigationBarHidden(true, animated: true)
//                self.navigationController?.setStatusBar(alpha: Float(offset))
            }
        }
    }
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        let pageNumber = promotionScrollView.contentOffset.x / promotionScrollView.frame.size.width
//        pageControl.currentPage = Int(pageNumber)
//    }
}

extension HomeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == nearMeCollectionView {
            return currentNearMeArray.count
        }
        else if collectionView == popularCafeCollectionView {
            return currentPopularArray.count
        }
        else {
            return promotionArray.count
        }
    }
    
    //edge inset
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == nearMeCollectionView || collectionView == popularCafeCollectionView {
            return UIEdgeInsets(top: 0, left: 10, bottom: 10, right: 10)
        }
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    //line spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == nearMeCollectionView || collectionView == popularCafeCollectionView {
            return 10
        }
        return 0
    }
    
    //inter item spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == nearMeCollectionView || collectionView == popularCafeCollectionView {
            return 5
        }
        return 0
    }
    
    //size of cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == nearMeCollectionView || collectionView == popularCafeCollectionView {
            let numberOfItemPerRow: CGFloat = 2
            let interItemSpacing: CGFloat = 5
            let width = (nearMeCollectionView.frame.width - 20 - (numberOfItemPerRow * interItemSpacing)) / numberOfItemPerRow
            return CGSize(width: width, height: 158)
        }
        let size = promotionCollectionView.frame.size
        return CGSize(width: size.width, height: size.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == nearMeCollectionView {
            let cell = nearMeCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! NearMeCell
            let cafe = currentNearMeArray[indexPath.item]
            cell.cafeNameLabel.text = cafe.cafename_en

            let distance = changeDistanceToString(rawDistance: cafe.rawDistance)
            cell.distanceLabel.text = distance
            
            cell.reviewTotalLabel.text = "\(cafe.reviewTotal) รีวิว"
            cell.ratingLabel.text = "\(cafe.rating)"
            if cafe.imageURL == "" {
                cell.cafeImage.image = UIImage(named: "background.png")
            } else {
                getData.getImage(imageURL: cafe.imageURL, imageView: cell.cafeImage)
            }
            
            return cell
        }
        else if collectionView == popularCafeCollectionView {
            let cell = popularCafeCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! NearMeCell
            let cafe = currentPopularArray[indexPath.item]
            cell.cafeNameLabel.text = cafe.cafename_en
            
            let distance = changeDistanceToString(rawDistance: cafe.rawDistance)
            cell.distanceLabel.text = distance
            
            cell.reviewTotalLabel.text = "\(cafe.reviewTotal) รีวิว"
            cell.ratingLabel.text = "\(cafe.rating)"
            if cafe.imageURL == "" {
                cell.cafeImage.image = UIImage(named: "background.png")
            } else {
                getData.getImage(imageURL: cafe.imageURL, imageView: cell.cafeImage)
            }
            return cell
        }
        else {
            let cell = promotionCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier2, for: indexPath) as! PromotionHomeCell
            let promotion = promotionArray[indexPath.item]
            if promotion.promotion_imageURL == "" {
                cell.promotionImage.image = UIImage(named: "background.png")
            } else {
                getData.getImage(imageURL: promotion.promotion_imageURL, imageView: cell.promotionImage)
            }
            cell.promotionTopicLabel.text = promotion.promotion_topic
            cell.cafeNameLabel.text = promotion.cafename_en
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == nearMeCollectionView {
            let cafeDetailVC = storyboard?.instantiateViewController(withIdentifier: "CafeDetail") as! CafeDetailViewController
            self.navigationController?.pushViewController(cafeDetailVC, animated: true)
            let cafe : CafeData
            cafe = currentNearMeArray[indexPath.item]
            cafeDetailVC.cafeData = cafe
        }
        else if collectionView == popularCafeCollectionView {
            let cafeDetailVC = storyboard?.instantiateViewController(withIdentifier: "CafeDetail") as! CafeDetailViewController
            self.navigationController?.pushViewController(cafeDetailVC, animated: true)
            let cafe : CafeData
            cafe = currentPopularArray[indexPath.item]
            cafeDetailVC.cafeData = cafe
        }
        else {
            let promotionDetailVC = storyboard?.instantiateViewController(withIdentifier: "PromotionDetailVC") as! PromotionDetailViewController
            self.navigationController?.pushViewController(promotionDetailVC, animated: true)
            let promotion : PromotionData
            promotion = promotionArray[indexPath.item]
            promotionDetailVC.promotionData = promotion
        }
    }
}

extension HomeViewController {
    
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
