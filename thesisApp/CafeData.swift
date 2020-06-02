//
//  cafeData.swift
//  thesisApp
//
//  Created by Bambam on 13/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import Foundation
import Firebase
import FirebaseUI
import CoreLocation

class CafeData {
    var cafe_id : String
    var cafename_en : String
    var cafename_th : String
    var style : String
    var area_en : String
    var area_th : String
    var imageURL : String
    var rating : Float
    var rawDistance : Double
    var reviewTotal: Int
    
    init(cafe_id: String,cafename_en: String, cafename_th: String, style: String, area_en: String, area_th: String, imageURL: String, rating: Float, rawDistance: Double, reviewTotal: Int) {
        self.cafe_id = cafe_id
        self.cafename_en = cafename_en
        self.cafename_th = cafename_th
        self.style = style
        self.area_en = area_en
        self.area_th = area_th
        self.imageURL = imageURL
        self.rating = rating
        self.rawDistance = rawDistance
        self.reviewTotal = reviewTotal
    }
}

class RewardCafeListData {
    var cafe_id : String
    var cafename_en : String
    var type : String
    var reward : String
    var logoURL : String
    
    init(cafe_id: String ,cafename_en: String, type: String, reward: String, logoURL: String) {
        self.cafe_id = cafe_id
        self.cafename_en = cafename_en
        self.type = type
        self.reward = reward
        self.logoURL = logoURL
    }
}

class CardCafeListData {
    var cafe_id : String
    var cafename_en : String
    var type : String
    var user_point : Int
    var total_point : Int
    var coverURL : String
    var logoURL : String
    var createdate : Timestamp
    var exp_date : String
    var color : [String: Float]
    
    init(cafe_id: String ,cafename_en: String, type: String, user_point: Int, total_point: Int, logoURL: String, coverURL: String, createdate : Timestamp, exp_date: String, color: [String: Float]) {
        self.cafe_id = cafe_id
        self.cafename_en = cafename_en
        self.type = type
        self.user_point = user_point
        self.total_point = total_point
        self.logoURL = logoURL
        self.coverURL = coverURL
        self.createdate = createdate
        self.exp_date = exp_date
        self.color = color
    }
}

class ReviewData {
    var review_id : String
    var username : String
    var cafename_en : String
    var cafe_id : String
    var rating : Float
    var timeInterval : TimeInterval
    var review_text : String
    
    init(review_id: String, username: String, cafename_en: String, cafe_id : String, rating: Float, timeInterval: TimeInterval, review_text: String) {
        self.review_id = review_id
        self.username = username
        self.cafename_en = cafename_en
        self.cafe_id = cafe_id
        self.rating = rating
        self.timeInterval = timeInterval
        self.review_text = review_text
    }
}

class CafeQueueData {
    var cafe_id : String
    var cafename_en : String
    var cafename_th : String
    var area_th : String
    var ll_location : GeoPoint
    var queue : Int
    var logoURL : String
    var rawDistance : Double
    var booking_time : String
    
    init(cafe_id: String, cafename_en: String, cafename_th: String, area_th: String, ll_location: GeoPoint, rawDistance : Double, queue: Int, logoURL: String, booking_time : String) {
        self.cafe_id = cafe_id
        self.cafename_en = cafename_en
        self.cafename_th = cafename_th
        self.area_th = area_th
        self.ll_location = ll_location
        self.rawDistance = rawDistance
        self.queue = queue
        self.logoURL = logoURL
        self.booking_time = booking_time
    }
}

class QueueData {
    var document_id : String
    var queue_no : String
    var category : String
    var cafe_id : String
    var cafename_en : String
    var area_th : String
    var number_people : Int
    var timeInterval : Double
    
    init(document_id: String, queue_no: String, category: String, cafe_id: String, cafename_en: String, area_th: String, number_people: Int, timeInterval: Double) {
        self.document_id = document_id
        self.queue_no = queue_no
        self.category = category
        self.cafe_id = cafe_id
        self.cafename_en = cafename_en
        self.area_th = area_th
        self.number_people = number_people
        self.timeInterval = timeInterval
    }
}

class GetData : NSObject {
    
    let db = Firestore.firestore()
    var rating = Float()
    var x = Float()
    var image = UIImage()
    
    func getImage(imageURL:String, imageView: UIImageView) {
        if imageURL != "" {
            let storageRef = Storage.storage().reference(forURL: imageURL)
            imageView.sd_setImage(with: storageRef, placeholderImage: UIImage(named: "background.png"))
        }
        else {
            imageView.image = UIImage(named: "background.png")
        }
    }
    
    func calculateRating(cafe_id: String) {
        let data = self.db.collection("review").whereField("cafe_id", isEqualTo: cafe_id)
        data.getDocuments { (snapshot, error) in
            if error == nil && snapshot != nil {
                let people = snapshot!.documents.count
                self.rating = 0
                for document in snapshot!.documents {
                    let rate = document.get("rating") as! Float
                    print("คนแรก \(rate)")
                    self.rating += rate
                }
                print("rating \(self.rating)")
                print("กี่คน \(people)")
                self.x = self.rating / Float(people)
                print("x \(self.x)")
                let number = Float(String(format: "%.1f", self.x))!
                self.addRatingToCafe(rating: number, cafe_id: cafe_id)
            }
        }
    }
    
    func addRatingToCafe(rating:Float, cafe_id: String) {
        print(rating)
        let data = [
            "rating": rating
        ] as [String : Float]
        
        //add user data to firestore
        self.db.collection("cafe").document(cafe_id).updateData(data) { err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully updated!")
            }
        }
    }
    
    func createCafeData() {
        var ref: DocumentReference? = nil
        ref = db.collection("cafe").addDocument(data: [
            "area_th": "อารีย์",
            "area_en": "Ari",
            "cafe_id": "",
            "cafe_tel": "0892624661, 0832987288, 0841109865",
            "cafename_en": "Thongyoy Cafe",
            "cafename_th": "ทองย้อย คาเฟ่",
            "carpark": true,
            "creditcard": false,
            "delivery": true,
            "location": "พระรามที่ 6 ซอย 30 กรุงเทพมหานคร (ร้านอยู่ปากซอยอารีย์สัมพันธ์ 7 ตรงข้ามธนาคารไทยพาณิชย์)",
            "membercard": true,
            "price": "101 - 250",
            "rating": 4.599999904632568,
            "style": "น่ารัก, ดอกไม้, ขนมไทย",
            "table_amount": "41 - 80",
            "time": ["Mon" : "08:00 - 21:00",
                     "Tue" : "08:00 - 21:00",
                     "Wed" : "08:00 - 21:00",
                     "Thur" : "08:00 - 21:00",
                     "Fri" : "08:00 - 21:00",
                     "Sat" : "10:00 - 22:00",
                     "Sun" : "10:00 - 22:00",
            ],
            "type": "ร้านคาเฟ่ขนมไทย, ร้านเสื้อผ้า",
            "wifi": true,
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
                let r = self.db.collection("cafe").document(ref!.documentID)
                r.updateData([
                    "cafe_id" : "\(ref!.documentID)"
                ]) { err in
                    if let err = err {
                        print("Error updating document: \(err)")
                    } else {
                        print("Document successfully updated")
                    }
                }

            }
        }
    }
    
    func createCafeImage() {
        let cafe = db.collection("cafe")
        cafe.getDocuments { (snapshot, error) in
            if error == nil && snapshot != nil {
                for document in snapshot!.documents {
                    let cafe_id = document.get("cafe_id") as! String
                    let cafename_en = document.get("cafename_en") as! String
                    self.db.collection("cafe_image").document(cafe_id).setData([
                        "cafename_en": cafename_en,
                        "cafe_id": cafe_id,
                        "cafe_cover": "",
                        "cafe_logo": "",
                        "cafe_menu": [],
                        "cafe_image": []
                    ]) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                        }
                    }
                }
            }
        }
    }
}

extension UIViewController {
    
    func setupNavigationBarItems() {
        let backButton = UIButton()
        backButton.setImage(UIImage(named: "back_red.png"), for: .normal)
        backButton.addTarget(self, action: #selector(backToPrevious), for: .touchUpInside)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 28)
        
        let menuBarItem = UIBarButtonItem(customView: backButton)
        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 40)
        let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 20)
        currWidth?.isActive = true
        currHeight?.isActive = true
    
        navigationItem.leftBarButtonItem = menuBarItem
    }
    
    @objc func backToPrevious() {
        performSegueToReturnBack()
    }
    
    func performSegueToReturnBack()  {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func hideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer( target: self, action: #selector(UIViewController.dismissKeyboard))
            tap.cancelsTouchesInView = false; view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func createDocumentID(id: String,counts: Int) -> String {
        var userid = String()
        var number = Int()
        number = counts + 1
        userid = "\(id)\(String(format: "%06d", number))" //%06d ทำให้ตัวเลขมี 6 ตำแหน่ง user000012
        return userid
    }
    
    func currentLocation() -> (Double,Double) {
        let locationManager = CLLocationManager()
        var latitude: Double = 0
        var longitude: Double = 0
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        var currentLocation: CLLocation!
        if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways) {currentLocation = locationManager.location
            latitude = currentLocation.coordinate.latitude
            longitude = currentLocation.coordinate.longitude
        }
        return (latitude, longitude)
    }

    func calculateDistance(userLocationX: Double, userLocationY: Double, cafeLocationX: Double, cafeLocationY: Double) -> Double {
        let userCoordinate = CLLocation(latitude: userLocationX, longitude: userLocationY)
        let cafeCoordinate = CLLocation(latitude: cafeLocationX, longitude: cafeLocationY)
        let rawDistance = userCoordinate.distance(from: cafeCoordinate) // result is in meters
        return rawDistance
    }
    
    //เปลี่ยน distance ให้เป็น string แบบ km, m
    func changeDistanceToString(rawDistance: Double) -> String {
        let distance = round(rawDistance)
        if String(Int(distance)).count > 3 {
            let dis = distance/1000
            let distanceKM = String(format: "%.1f", dis)
            return "\(distanceKM) km"
        }
        else {
            let distanceM = String(Int(distance))
            return "\(distanceM) m"
        }
    }
    
    func getCurrentWeekday() -> String {
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
        return weekdayString
    }
}

extension UITextField {
    func setBottomBorder() {
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 0.0
    }
    
    func addImage(image: UIImage) {
        let iconView = UIImageView(frame: CGRect(x: 10, y: 10, width: 18, height: 18)) // set your Own size
        iconView.image = image
        let iconContainerView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 45))
        iconContainerView.addSubview(iconView)
        self.rightView = iconContainerView
        self.rightViewMode = .always
    }
    
    enum Direction {
        case Left
        case Right
    }

    // add image to textfield
    func withImage(direction: Direction, image: UIImage, colorSeparator: UIColor, colorBorder: UIColor){
        let mainView = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 45))
        mainView.layer.cornerRadius = 5

        let view = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 45))
        view.backgroundColor = .white
        view.clipsToBounds = true
        view.layer.cornerRadius = 5
        view.layer.borderWidth = CGFloat(0.5)
        view.layer.borderColor = colorBorder.cgColor
        mainView.addSubview(view)

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 12.0, y: 10.0, width: 24.0, height: 24.0)
        view.addSubview(imageView)

        if(Direction.Left == direction){ // image left
            self.leftViewMode = .always
            self.leftView = mainView
        } else { // image right
            self.rightViewMode = .always
            self.rightView = mainView
        }

        self.layer.borderColor = colorBorder.cgColor
        self.layer.borderWidth = CGFloat(0.5)
        self.layer.cornerRadius = 5
    }
}

extension UIColor {
    func as1ptImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        setFill()
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UILabel {
    
    func buttomBorder(color: CGColor) {
        // For Buttom Border
        let bottomLayer = CALayer()
        bottomLayer.frame = CGRect(x: 0, y: self.frame.height - 15, width: self.frame.width - 1, height: 2.5)
        bottomLayer.backgroundColor = color
        layer.addSublayer(bottomLayer)
    }
    
    func setImageInLabel(text: String, image: UIImage, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: x, y: y, width: width, height: height)
        let attachmentString = NSAttributedString(attachment: attachment)
        let myString = NSMutableAttributedString(string: "")
        
        if text == "" {
            myString.append(attachmentString)
            self.attributedText = myString
        }
        else {
            let myString1 = NSMutableAttributedString(string: " \(text)")
            myString.append(attachmentString)
            myString.append(myString1)
            self.attributedText = myString
        }
    }
}

extension UINavigationController {

    func setStatusBar(alpha: Float) {
        let statusBarFrame: CGRect
        if #available(iOS 13.0, *) {
            statusBarFrame = view.window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero
        } else {
            statusBarFrame = UIApplication.shared.statusBarFrame
        }
        let statusBarView = UIView(frame: statusBarFrame)
        statusBarView.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: CGFloat(alpha))
        view.addSubview(statusBarView)
        view.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: CGFloat(alpha))
    }
}
