//
//  CafeDetailViewController.swift
//  thesisApp
//
//  Created by Bambam on 15/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import MapKit

struct Item {
    var picURL: String
}


///get data back from another view controller
extension CafeDetailViewController: PostReviewDelegate, BookQueueDelegate {
    func bookSuccess(success: Bool) {
        self.success = success
    }
    
    func postReview(post: Bool) {
        self.post = post
    }
}

class CafeDetailViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var styleLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var getDirectionButton: UIButton!
    @IBOutlet weak var bookingQueueButton: UIButton!
    @IBOutlet weak var bookingQueueLabel: UILabel!
    @IBOutlet weak var telButton: UIButton!
    @IBOutlet weak var menuButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var reviewButton: UIButton!
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    
    @IBOutlet weak var starButton1: UIButton!
    @IBOutlet weak var starButton2: UIButton!
    @IBOutlet weak var starButton3: UIButton!
    @IBOutlet weak var starButton4: UIButton!
    @IBOutlet weak var starButton5: UIButton!
    @IBOutlet weak var writeReviewButton: UIButton!
    @IBOutlet weak var reviewTotalLabel: UILabel!
    @IBOutlet weak var miniReviewCollectionView: UICollectionView!
    @IBOutlet weak var miniReviewCollectionViewHeight: NSLayoutConstraint! //ประกาศไว้เพื่อให้ความยาวของ collectionViewHeight = contentSize
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    //more info
    @IBOutlet weak var timeTopic: UILabel!
    @IBOutlet weak var priceTopic: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var facilitiesView: UIView!
    @IBOutlet weak var wifi: UILabel!
    @IBOutlet weak var carpark: UILabel!
    @IBOutlet weak var creditcard: UILabel!
    @IBOutlet weak var delivery: UILabel!
    @IBOutlet weak var seat: UILabel!
    @IBOutlet weak var seatLabel: UILabel!
    
    @IBOutlet weak var monday: UILabel!
    @IBOutlet weak var mon: UILabel!
    @IBOutlet weak var tuesday: UILabel!
    @IBOutlet weak var tue: UILabel!
    @IBOutlet weak var wednesday: UILabel!
    @IBOutlet weak var wed: UILabel!
    @IBOutlet weak var thursday: UILabel!
    @IBOutlet weak var thur: UILabel!
    @IBOutlet weak var friday: UILabel!
    @IBOutlet weak var fri: UILabel!
    @IBOutlet weak var saturday: UILabel!
    @IBOutlet weak var sat: UILabel!
    @IBOutlet weak var sunday: UILabel!
    @IBOutlet weak var sun: UILabel!
    @IBOutlet weak var checkWifi: UIImageView!
    @IBOutlet weak var checkSeat: UIImageView!
    @IBOutlet weak var checkCarpark: UIImageView!
    @IBOutlet weak var checkOnlinePayment: UIImageView!
    @IBOutlet weak var checkCreditcard: UIImageView!
    @IBOutlet weak var checkDelivery: UIImageView!

    @IBOutlet var mapView: MKMapView!
    
    var collectionViewFlowLayout : UICollectionViewFlowLayout!
    let cellIdentifier1 = "ImageCollectionViewCell"
    let cellIdentifier2 = "MiniReviewCell"
    let headerId = "headerId"
    let footerId = "footerId"
    
    var cafeData : CafeData!
    let getData = GetData()
    var rating : Float = 0.0
    let db = Firestore.firestore()
    var items = [String]()
    var reviews = [ReviewData]()
    var imageURL = [ImageURL]()
    var reviewTotal = Int()
    var selectedImage = String()
    let showReviewVC = ShowReviewViewController()
    let reviewVC = ReviewViewController()
    var latitude: Double!
    var longitude: Double!
    var post = false
    var success = false
    var ll_locationLB = UILabel()
    var queueLB = UILabel()
    var logoURLLB = UILabel()
    var vSpinner: UIView?
    var bookingTimeLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loading(self.view)
        self.navigationItem.title = cafeData.cafename_en
        setButton()
        showData()
        setupCollectionView()
        getAllCafeImageURL()
        
        getDataReview()
        checkFavorite()
        setPinUsingMKPointAnnotation()
        
        checkReviewTotal()
        getCafeQueueData()
        
        getDirectionButton.addTarget(self, action: #selector(openMaps), for: .touchUpInside)
        bookingQueueButton.addTarget(self, action: #selector(openBookingQueue), for: .touchUpInside)
        addressButton.addTarget(self, action: #selector(goFullMap), for: .touchUpInside)
        mapButton.addTarget(self, action: #selector(goFullMap), for: .touchUpInside)
        menuButton.addTarget(self, action: #selector(openMenuVC), for: .touchUpInside)
        writeReviewButton.addTarget(self, action: #selector(openReview), for: .touchUpInside)
        reviewButton.addTarget(self, action: #selector(openReview), for: .touchUpInside)
        starButton1.addTarget(self, action: #selector(star1), for: .touchUpInside)
        starButton2.addTarget(self, action: #selector(star2), for: .touchUpInside)
        starButton3.addTarget(self, action: #selector(star3), for: .touchUpInside)
        starButton4.addTarget(self, action: #selector(star4), for: .touchUpInside)
        starButton5.addTarget(self, action: #selector(star5), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if post == true {
            self.performSegue(withIdentifier: "goShowReview", sender: self)
            post = false
        }
        if success == true {
            //เปลี่ยนไป tab my queue
            self.tabBarController?.selectedIndex = 2
            let navVC = tabBarController?.viewControllers![2] as! UINavigationController
            let myQueueVC = navVC.topViewController as! MyQueueViewController
            myQueueVC.newQueue = success
            success = false
        }
    }

    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setupCollectionViewItemSize()
    }
    
    ///คำสั่งที่ทำให้ความยาวของ collection view เท่ากับส่วน content
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let height = miniReviewCollectionView.collectionViewLayout.collectionViewContentSize.height
        miniReviewCollectionViewHeight.constant = height
        self.view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        tabBarController?.tabBar.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool){
        super.viewWillDisappear(animated)
//        tabBarController?.tabBar.isHidden = false
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "goShowReview") {
            let showReviewVC = segue.destination as! ShowReviewViewController
            showReviewVC.cafeData = cafeData
            showReviewVC.from = "cafeDetailVC"
        }
    }
    
    func setButton() {
        bookmarkButton.setImage(UIImage(named: "bookmark1.png"), for: .normal)
        
        addressButton.imageView?.contentMode = .scaleAspectFit
        addressButton.setImage(UIImage(named: "locationpin.png"), for: .normal)
        addressButton.imageEdgeInsets = UIEdgeInsets(top: 33, left: -10, bottom: 33, right: 0)
        addressButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 10)
        
        menuButton.imageView?.contentMode = .scaleAspectFit
        menuButton.setImage(UIImage(named: "fork.png"), for: .normal)
        menuButton.imageEdgeInsets = UIEdgeInsets(top: 15, left: -10, bottom: 15, right: 0)
        menuButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 10)
            
        telButton.imageView?.contentMode = .scaleAspectFit
        telButton.setImage(UIImage(named: "tel.png"), for: .normal)
        telButton.imageEdgeInsets = UIEdgeInsets(top: 16, left: -10, bottom: 16, right: 0)
        telButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 10)
    }
    
    func getLatitudeAndLongitude(cafe_id: String, dispatch:DispatchGroup, completed: @escaping (Double,Double) -> Void) {
        let data = db.collection("cafe").document(cafe_id)
        dispatch.enter()
        data.getDocument { (document, err) in
            if let document = document, document.exists {
                let ll_location = document.get("ll_location") as! GeoPoint
                self.latitude = ll_location.latitude
                self.longitude = ll_location.longitude
            }
            else {
                print("Document does not exist")
            }
            dispatch.leave()
        }
        dispatch.notify(queue: .main, execute: {
            completed(self.latitude,self.longitude)
        })
    }
    
    func setPinUsingMKPointAnnotation(){
        let dispatch = DispatchGroup()
        self.getLatitudeAndLongitude(cafe_id: cafeData.cafe_id, dispatch: dispatch){ (latitude,longitude) in
            dispatch.notify(queue: .main, execute: {
                let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
//                    annotation.title = "Here"
//                    annotation.subtitle = "Device Location"
                self.mapView.addAnnotation(annotation)
                        
                    let region = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 300, longitudinalMeters: 300)
                self.mapView.setRegion(region, animated: true)
            })
        }
    }
    
    @objc func openMenuVC() {
        let menuVC = storyboard?.instantiateViewController(withIdentifier: "MenuVC") as! MenuViewController
        menuVC.cafe_id = cafeData.cafe_id
        self.navigationController?.pushViewController(menuVC, animated: true)
    }
    
    @objc func openReview() {
        if Auth.auth().currentUser != nil {
            let reviewVC = self.storyboard?.instantiateViewController(withIdentifier: "ReviewVC") as! ReviewViewController
            reviewVC.delegate = self
            reviewVC.cafeData = cafeData
            let navController = UINavigationController(rootViewController: reviewVC)
            reviewVC.modalPresentationStyle = .fullScreen
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated:true, completion: nil)
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
            vc.from = "CafeDetailVC"
            self.present(vc, animated: true, completion: nil)
        }
//        self.performSegue(withIdentifier: "goReview", sender: self)
    }
    
    @objc func openMaps() {
        let locationName = cafeData.cafename_en
        let appleMapsURL = URL(string: "http://maps.apple.com")!
        let googleMapsURL = URL(string: "comgooglemaps-x-callback://")!
        
        let dispatch = DispatchGroup()
        getLatitudeAndLongitude(cafe_id: cafeData.cafe_id, dispatch: dispatch){ (lat,long) in
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
    
    @objc func goFullMap() {
        let mapVC =  storyboard?.instantiateViewController(withIdentifier: "Map") as! MapViewController
        self.navigationController?.pushViewController(mapVC, animated: true)
        mapVC.latitude = latitude
        mapVC.longitude = longitude
        mapVC.cafename_en = cafeData.cafename_en
        mapVC.cafe_id = cafeData.cafe_id
    }
    
    @IBAction func phoneCallActionSheet(_ sender: UIButton) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let text = telButton.titleLabel?.text {
            print(text)
            let phoneNumberArray = text.components(separatedBy: ", ")
            for phoneNumber in phoneNumberArray {
                let phoneCallAction = UIAlertAction(title: phoneNumber, style: .default) { (action) in
                    if let url = URL(string: "tel://\(phoneNumber)"),
                    UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                optionMenu.addAction(phoneCallAction)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        optionMenu.addAction(cancelAction)
            
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    @IBAction func goBack(_ sender: UIButton) {
        performSegueToReturnBack()
    }
    
    @IBAction func favThisCafe(_ sender: UIButton) {
        let cafeid = cafeData.cafe_id
        print(cafeid)
        //add to favorite
        if Auth.auth().currentUser != nil {
            if bookmarkButton.currentImage == UIImage(named: "bookmark1.png") {
                bookmarkButton.setImage(UIImage(named: "bookmark2.png"), for: .normal)
                addToFavorite(cafe_id: cafeid)
                print("add")
            }
            //remove from favorite
            else {
                bookmarkButton.setImage(UIImage(named: "bookmark1.png"), for: .normal)
                removeFromFavorite(cafe_id: cafeid)
                print("remove")
            }
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
            vc.from = "CafeDetailVC"
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    ///star button action
    @objc func star1() {
        if Auth.auth().currentUser != nil {
            reviewVC.starAction(star: 1, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
            let reviewVC1 = self.storyboard?.instantiateViewController(withIdentifier: "ReviewVC") as! ReviewViewController
            reviewVC1.delegate = self
            reviewVC1.cafeData = cafeData
            reviewVC1.rating = 1
            let navController = UINavigationController(rootViewController: reviewVC1)
            reviewVC1.modalPresentationStyle = .fullScreen
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated:true, completion: nil)
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
            vc.from = "CafeDetailVC"
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func star2() {
        if Auth.auth().currentUser != nil {
            reviewVC.starAction(star: 2, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
            let reviewVC1 = self.storyboard?.instantiateViewController(withIdentifier: "ReviewVC") as! ReviewViewController
            reviewVC1.delegate = self
            reviewVC1.cafeData = cafeData
            reviewVC1.rating = 2
            let navController = UINavigationController(rootViewController: reviewVC1)
            reviewVC1.modalPresentationStyle = .fullScreen
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated:true, completion: nil)
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
            vc.from = "CafeDetailVC"
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func star3() {
        if Auth.auth().currentUser != nil {
            reviewVC.starAction(star: 3, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
            let reviewVC1 = self.storyboard?.instantiateViewController(withIdentifier: "ReviewVC") as! ReviewViewController
            reviewVC1.delegate = self
            reviewVC1.cafeData = cafeData
            reviewVC1.rating = 3
            let navController = UINavigationController(rootViewController: reviewVC1)
            reviewVC1.modalPresentationStyle = .fullScreen
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated:true, completion: nil)
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
            vc.from = "CafeDetailVC"
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func star4() {
        if Auth.auth().currentUser != nil {
            reviewVC.starAction(star: 4, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
            let reviewVC1 = self.storyboard?.instantiateViewController(withIdentifier: "ReviewVC") as! ReviewViewController
            reviewVC1.delegate = self
            reviewVC1.cafeData = cafeData
            reviewVC1.rating = 4
            let navController = UINavigationController(rootViewController: reviewVC1)
            reviewVC1.modalPresentationStyle = .fullScreen
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated:true, completion: nil)
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
            vc.from = "CafeDetailVC"
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    @objc func star5() {
        if Auth.auth().currentUser != nil {
            reviewVC.starAction(star: 5, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
            let reviewVC1 = self.storyboard?.instantiateViewController(withIdentifier: "ReviewVC") as! ReviewViewController
            reviewVC1.delegate = self
            reviewVC1.cafeData = cafeData
            reviewVC1.rating = 5
            let navController = UINavigationController(rootViewController: reviewVC1)
            reviewVC1.modalPresentationStyle = .fullScreen
            navController.modalPresentationStyle = .fullScreen
            self.present(navController, animated:true, completion: nil)
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
            vc.from = "CafeDetailVC"
            self.present(vc, animated: true, completion: nil)
        }
    }

    private func setupCollectionView() {
        imageCollectionView.delegate = self
        imageCollectionView.dataSource = self
        let nib1 = UINib(nibName: "ImageCollectionViewCell", bundle: nil)
        imageCollectionView.register(nib1, forCellWithReuseIdentifier: cellIdentifier1)
        
        miniReviewCollectionView.delegate = self
        miniReviewCollectionView.dataSource = self
        let nib2 = UINib(nibName: "MiniReviewCell", bundle: nil)
        miniReviewCollectionView.register(nib2, forCellWithReuseIdentifier: cellIdentifier2)
        miniReviewCollectionView.backgroundColor = .init(red: 240/255, green: 240/255, blue: 241/255, alpha: 1)
    }
    
    private func setupCollectionViewItemSize() {
        if collectionViewFlowLayout == nil {
            let numberOfItemPerRow: CGFloat = 3
            let lineSpacing: CGFloat = 5
            let interItemSpacing: CGFloat = 5
            
            let width = (imageCollectionView.frame.width - (numberOfItemPerRow - 1) * interItemSpacing) / numberOfItemPerRow
            let height = width
            
            collectionViewFlowLayout = UICollectionViewFlowLayout()
            
            collectionViewFlowLayout.itemSize = CGSize(width: width, height: height)
            collectionViewFlowLayout.sectionInset = UIEdgeInsets.zero
            collectionViewFlowLayout.scrollDirection = .vertical
            collectionViewFlowLayout.minimumLineSpacing = lineSpacing
            collectionViewFlowLayout.minimumInteritemSpacing = interItemSpacing
            
            imageCollectionView.setCollectionViewLayout(collectionViewFlowLayout, animated: true)
        }
    }
    
    func getAllCafeImageURL() {
        let cafeid = cafeData.cafe_id
        let data = self.db.collection("cafe_image").document(cafeid)
        data.getDocument { (document, err) in
            if let document = document, document.exists {
                let images = document.get("cafe_image") as! [String]
                self.items = images
            } else {
                print("Document does not exist")
            }
            self.removeLoading()
            self.imageCollectionView.reloadData()
        }
    }
    
    private func showData() {
        if cafeData.cafename_th != "" {
            nameLabel.text = "\(cafeData.cafename_en) \(cafeData.cafename_th)"
        }
        else {
            nameLabel.text = cafeData.cafename_en
        }

        styleLabel.text = cafeData.style
        ratingLabel.text = "\(cafeData.rating)"
        getData.getImage(imageURL: cafeData.imageURL, imageView: coverImage)
        showMoreData()
    }
    
    private func showMoreData() {
        let cafe_id = cafeData.cafe_id
        let data = db.collection("cafe").document(cafe_id)
        data.getDocument { (document, err) in
            if let document = document, document.exists {
                let location = document.get("location") as! String
                let tel = document.get("cafe_tel") as! [String]
                let seat = document.get("table_amount") as! String
                let price = document.get("price") as! String
                let wifi1 = document.get("wifi") as! Bool
                let carpark1 = document.get("carpark") as! Bool
                let onlinePayment1 = document.get("onlinePayment") as! Bool
                let creditcard1 = document.get("creditcard") as! Bool
                let delivery1 = document.get("delivery") as! Bool
                
                //show location
                self.addressButton.setTitle(location, for: .normal)
                //show tel
                self.telButton.setTitle(tel[0], for: .normal)
                //show seat,
                self.seatLabel.text = "\(seat)"
                //show price
                self.priceLabel.text = "\(price)"
                //show check facilities
                self.checkWifi.image = UIImage(named: self.checkFacilities(check: wifi1))
                self.checkCarpark.image = UIImage(named: self.checkFacilities(check: carpark1))
                self.checkOnlinePayment.image = UIImage(named: self.checkFacilities(check: onlinePayment1))
                self.checkCreditcard.image = UIImage(named: self.checkFacilities(check: creditcard1))
                self.checkDelivery.image = UIImage(named: self.checkFacilities(check: delivery1))
                
                if seat != "" {
                    self.checkSeat.image = UIImage(named: self.checkFacilities(check: true))
                }
                else {
                    self.checkSeat.image = UIImage(named: self.checkFacilities(check: false))
                }
                
                //show time
                let time = document.get("opening_time") as! [String : String]
                for tt in time {
                    switch tt.key {
                    case "Monday":
                        self.mon.text = tt.value
                        self.checkCurrentWeekday(weekday: "Monday", weekdayTitle: self.monday, weekdayLabel: self.mon)
                    case "Tuesday":
                        self.tue.text = tt.value
                        self.checkCurrentWeekday(weekday: "Tuesday", weekdayTitle: self.tuesday, weekdayLabel: self.tue)
                    case "Wednesday":
                        self.wed.text = tt.value
                        self.checkCurrentWeekday(weekday: "Wednesday", weekdayTitle: self.wednesday, weekdayLabel: self.wed)
                    case "Thursday":
                        self.thur.text = tt.value
                        self.checkCurrentWeekday(weekday: "Thursday", weekdayTitle: self.thursday, weekdayLabel: self.thur)
                    case "Friday":
                        self.fri.text = tt.value
                        self.checkCurrentWeekday(weekday: "Friday", weekdayTitle: self.friday, weekdayLabel: self.fri)
                    case "Saturday":
                        self.sat.text = tt.value
                        self.checkCurrentWeekday(weekday: "Saturday", weekdayTitle: self.saturday, weekdayLabel: self.sat)
                    default:
                        self.sun.text = tt.value
                        self.checkCurrentWeekday(weekday: "Sunday", weekdayTitle: self.sunday, weekdayLabel: self.sun)
                    }
                }
            } else {
                print("Document does not exist")
            }
            
        }
    }
    
    func checkCurrentWeekday(weekday: String, weekdayTitle: UILabel, weekdayLabel: UILabel) {
        var weekdayString = String()
        let date = Date()
        let calender = Calendar.current
        let currentWeekday = calender.component(.weekday, from: date)
        switch currentWeekday {
        case 1:
            weekdayString = "Sunday"
        case 2:
            weekdayString = "Monday"
        case 3:
            weekdayString = "Tuesday"
        case 4:
            weekdayString = "Wednesday"
        case 5:
            weekdayString = "Thursday"
        case 6:
            weekdayString = "Friday"
        case 7:
            weekdayString = "Saturday"
        default:
            print("Error fetching days")
            weekdayString = "Day"
        }
        if weekday == weekdayString {
            weekdayLabel.font = UIFont(name:"HelveticaNeue", size: 15)
            weekdayLabel.textColor = .init(red: 49/255, green: 49/255, blue: 51/255, alpha: 1)
            weekdayTitle.font = UIFont(name:"HelveticaNeue", size: 15)
            weekdayTitle.textColor = .init(red: 49/255, green: 49/255, blue: 51/255, alpha: 1)
        }
    }
    
    private func checkFacilities(check:Bool) -> String {
        var image = String()
        switch check{
        case true:
            image = "yes.png"
            return image
        default:
            image = "no.png"
            return image
        }
    }
    
    private func getDataReview() {
        let data = self.db.collection("review").order(by: "time", descending: true)
        data.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.imageURL.removeAll()
            self.reviews.removeAll()
            for doc in documents {
                let cafe_id = doc.get("cafe_id") as! String
                if cafe_id == self.cafeData.cafe_id {
                    let uid = doc.get("uid") as! String
                    let username = doc.get("username") as! String
                    let rating = doc.get("rating") as! Float
                    let timeInterval = doc.get("timeInterval") as! TimeInterval
                    let review_text = doc.get("review_text") as! String
                        
                    self.imageURL.append(ImageURL(id: uid, imageURL: ""))
                    self.reviews.append(ReviewData(review_id: doc.documentID, username: username, cafename_en: self.cafeData.cafename_en, cafe_id: cafe_id, rating: rating, timeInterval: timeInterval, review_text: review_text))
                }
                if self.reviews.count == 3 {
                    break
                }
            }
            let dispatch = DispatchGroup()
            self.showReviewVC.getImageURL(allId: self.imageURL, dispatch: dispatch){(array) in
                dispatch.notify(queue: .main, execute: {
                    self.imageURL.removeAll()
                    self.imageURL = array
                    DispatchQueue.main.async { self.miniReviewCollectionView.reloadData() }
                })
            }
        }
    }
    
    func checkReviewTotal() {
        let cafe_id = cafeData.cafe_id
        let data = self.db.collection("review").whereField("cafe_id", isEqualTo: cafe_id)
        data.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.reviewTotal = documents.count
            self.reviewTotalLabel.text = "   ความคิดเห็น (\(self.reviewTotal) รีวิว)"
            if self.reviewTotal == 0 {
                self.miniReviewCollectionView.isHidden = true
                self.scrollView.contentSize = CGSize(width: self.contentView.frame.width, height: self.contentView.frame.height - 440)
//                    print(self.contentView.frame.height)
//                    self.contentView.frame = CGRect(x: 0, y: 0, width: self.contentView.frame.width, height:  self.contentView.frame.height - 600)
            }
            else {
                self.miniReviewCollectionView.isHidden = false
                self.scrollView.contentSize = CGSize(width: self.contentView.frame.width, height: self.contentView.frame.height - 30)
            }
            self.miniReviewCollectionView.reloadData()
        }
    }
    
    func checkFavorite() {
        var fav = 0
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("favorite").whereField("uid", isEqualTo: uid).addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            fav = 0
            for document in documents {
                let cafeid = document.get("cafe_id") as! String
                if cafeid == self.cafeData.cafe_id {
                    print("fav \(self.cafeData.cafename_en)")
                    self.bookmarkButton.setImage(UIImage(named: "bookmark2.png"), for: .normal)
                    fav = 1
                }
            }
            if fav == 0 {
                print("unfav \(self.cafeData.cafename_en)")
                self.bookmarkButton.setImage(UIImage(named: "bookmark1.png"), for: .normal)
            }
        }
    }
    
    @objc func openBookingQueue() {
        let cafe_id = cafeData.cafe_id
        let cafename_en = cafeData.cafename_en
        let cafename_th = cafeData.cafename_th
        let area_th = cafeData.area_th
        let rawDistance = cafeData.rawDistance
        let booking_time = bookingTimeLabel.text ?? ""
        
        if booking_time == "หยุด" {
            let alert = UIAlertController(title: "วันนี้ร้านหยุดให้บริการ ขออภัยในความไม่สะดวก", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ตกลง", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        } else {
            let strArray = booking_time.components(separatedBy: " - ")
            let opening = strArray[0]
            let closing = strArray[1]
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "HH:mm"
            let dateString = formatter.string(from: now)
            if dateString >= opening && dateString <= closing {
                if rawDistance/1000 <= 22500.0 {
                    let queueData = CafeQueueData(
                        cafe_id: cafe_id,
                        cafename_en: cafename_en,
                        cafename_th: cafename_th,
                        area_th: area_th,
                        ll_location: GeoPoint(latitude: 11, longitude: 11),
                        rawDistance: cafeData.rawDistance,
                        queue: Int(queueLB.text!)!,
                        logoURL: logoURLLB.text!,
                        booking_time: booking_time)
                    
                    let bookQueueVC = self.storyboard?.instantiateViewController(withIdentifier: "BookQueueVC") as! BookQueueViewController
                    bookQueueVC.delegate = self
                    bookQueueVC.cafeQueueData = queueData
                    let navController = UINavigationController(rootViewController: bookQueueVC)
                    bookQueueVC.modalPresentationStyle = .fullScreen
                    navController.modalPresentationStyle = .fullScreen
                    self.present(navController, animated:true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "คุณอยู่ห่างจากร้านมากเกินไป เข้าใกล้ร้านขึ้นอีกนิดนะ", message: nil, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "ตกลง", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                }
            } else {
                let alert = UIAlertController(title: "ตอนนี้ร้านปิดรับคิว ขออภัยในความไม่สะดวก", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ตกลง", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    func getCafeQueueData() {
        let cafe_id = cafeData.cafe_id
        db.collection("cafe").document(cafe_id).getDocument { (document, err) in
            if let document = document, document.exists {
                let booking = document.get("booking") as! Bool
                if booking == true {
                    let timeArray = document.get("booking_time") as! [String: String]
                    let today = self.getCurrentWeekday()
                    if timeArray[today] != nil {
                        let time = timeArray[today] as! String
                        self.bookingTimeLabel.text = time
                    } else {
                        self.bookingTimeLabel.text = "หยุด"
                    }
                    let ll_location = document.get("ll_location") as! GeoPoint
                    
                    if document.get("queue") != nil {
                        let queue = document.get("queue") as! Int
                        self.queueLB.text = "\(queue)"
                    } else {
                        self.queueLB.text = "0"
                    }
                    self.db.collection("cafe_image").document(cafe_id).getDocument { (document, error) in
                        if let document = document, document.exists {
                            if document.get("cafe_logo") != nil && document.get("cafe_cover") != nil {
                                let logoURL = document.get("cafe_logo") as! String
                                if logoURL != "" {
                                    self.logoURLLB.text = logoURL
                                }
                            }
                        }
                        else {
                            print("Document does not exist")
                        }
                    }
                } else {
                    self.bookingQueueButton.isEnabled = false
                    self.bookingQueueLabel.textColor = .lightGray
                }
            }
            else {
                print("Document does not exist")
            }
        }
    }
    
    func addToFavorite(cafe_id: String) {
        var ref: DocumentReference? = nil
        guard let uid = Auth.auth().currentUser?.uid else { return }
        ref = db.collection("favorite").addDocument(data: [
            "uid": uid,
            "cafe_id": cafe_id,
            "createdate": FieldValue.serverTimestamp()
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
//                let favRef = self.db.collection("favorite").document(ref!.documentID)
//                favRef.updateData([
//                    "favorite_id" : "\(ref!.documentID)"
//                ]) { er in
//                    if let er = er {
//                        print("Error updating document: \(er)")
//                    } else {
//                        print("Document successfully updated")
//                    }
//                }
            }
        }
    }
    
    func removeFromFavorite(cafe_id: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("favorite").whereField("uid", isEqualTo: uid).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let favid = document.documentID
                    let cafeid = document.get("cafe_id") as! String
                    if cafeid == cafe_id {
                        self.db.collection("favorite").document(favid).delete() { err in
                            if let err = err {
                                print("Error removing document: \(err)")
                            } else {
                                print("Document successfully removed!")
                            }
                        }
                    }
                }
            }
        }
    }
}

extension CafeDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == miniReviewCollectionView {
            return reviews.count
        }
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == miniReviewCollectionView {
            return 1
        }
        else {
            return 5
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == imageCollectionView {
            let numberOfItemPerRow: CGFloat = 3
            let lineSpacing: CGFloat = 5
            let interItemSpacing: CGFloat = 5
            
            let width = (imageCollectionView.frame.width - (numberOfItemPerRow - 1) * interItemSpacing) / numberOfItemPerRow
            let height = width
            return CGSize(width: width, height: height)
        }
        else if collectionView == miniReviewCollectionView {
            if let user = reviews[indexPath.item] as? ReviewData {
                let approximateWidthOfReviewTextView = view.frame.width - 78
                let size = CGSize(width: approximateWidthOfReviewTextView, height: 1000)
                let attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15)]
                let estimatedFrame = NSString(string: user.review_text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
                return CGSize(width: view.frame.width, height: estimatedFrame.height + 85)
            }
        }
        
        return CGSize(width: view.frame.width, height: 200)
    }
    
    ///header and footer mini review
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if collectionView == miniReviewCollectionView {
            if kind == UICollectionView.elementKindSectionHeader {
                let header = miniReviewCollectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! HeaderMiniReview
                header.backgroundColor = .white
                header.headerLabel.text = "ความเห็นคิดจากผู้ใช้งาน"
                return header
            } else {
                let footer = miniReviewCollectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: footerId, for: indexPath) as! FooterMiniReview
                footer.backgroundColor = .white
                return footer
            }
        } else {
            let header = miniReviewCollectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as! HeaderMiniReview
            header.backgroundColor = .blue
            return header
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        if collectionView == miniReviewCollectionView {
//            return CGSize(width: view.frame.width, height: 45)
//        } else {
//            return CGSize(width: 0, height: 0)
//        }
//    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if collectionView == miniReviewCollectionView {
            if reviewTotal > 3 {
                return CGSize(width: view.frame.width, height: 45)
            }
            return CGSize(width: 0, height: 0)
        } else {
            return CGSize(width: 0, height: 0)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == imageCollectionView {
            let cell = imageCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier1, for: indexPath) as! ImageCollectionViewCell
            getData.getImage(imageURL: items[indexPath.item], imageView: cell.imageView)
            return cell
        }
        else {
            let cell = miniReviewCollectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier2, for: indexPath) as! MiniReviewCell
            cell.userName.text = reviews[indexPath.item].username
            cell.textReview.text = reviews[indexPath.item].review_text
            cell.starRate.image = showReviewVC.changeAllStarRateToImage(rating: reviews[indexPath.item].rating)

            //format date
            let timeFormat = DateFormatter()
            timeFormat.dateFormat = "MMM d, HH:mm"
            let timestamp = timeFormat.string(from: Date(timeIntervalSinceReferenceDate: reviews[indexPath.item].timeInterval))
            cell.timeReview.text = timestamp

            if imageURL[indexPath.item].imageURL != "" {
                getData.getImage(imageURL: imageURL[indexPath.item].imageURL, imageView: cell.userImage)
            }
            else {
                cell.userImage.image = UIImage(named: "profile.png")
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == imageCollectionView {
            selectedImage = items[indexPath.item]
            let showImageVC = storyboard?.instantiateViewController(withIdentifier: "ShowImageVC") as! ShowImageViewController
            showImageVC.indexPath = indexPath
            showImageVC.items = items
            showImageVC.cafename_en = cafeData.cafename_en
            self.navigationController?.pushViewController(showImageVC, animated: true)
        }
    }
}

extension CafeDetailViewController {
    
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
