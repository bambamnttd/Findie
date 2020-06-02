//
//  QueueViewController.swift
//  thesisApp
//
//  Created by Bambam on 12/3/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

extension QueueListViewController: BookQueueDelegate {
    func bookSuccess(success: Bool) {
        self.success = success
    }
}

class QueueListViewController: UIViewController {

    @IBOutlet weak var queueListTable: UITableView!
    
    let db = Firestore.firestore()
    var cafeArray = [CafeQueueData]()
    var currentCafeArray = [CafeQueueData]()
    let getData = GetData()
    var queueLabel = UILabel()
    var delegate: BookQueueDelegate?
    var success = false
    var vSpinner: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "จองคิว"
        navigationController?.navigationBar.isTranslucent = false
        setupNavigationBarItems()
        queueListTable.delegate = self
        queueListTable.dataSource = self
        getCafeData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("เข้าหรือไม่ \(success)")
        if success == true {
            //เปลี่ยนไป tab my queue
            delegate?.bookSuccess(success: true)
            performSegueToReturnBack()
            success = false
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        navigationController?.navigationBar.setBackgroundImage(UIColor.white.as1ptImage(), for: .default)
//        navigationController?.navigationBar.barTintColor = .green
    }

    override func viewWillDisappear(_ animated: Bool){
        navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        navigationController?.navigationBar.setBackgroundImage(UIColor.white.as1ptImage(), for: .default)
//        navigationController?.navigationBar.barTintColor = .white
    }
    
    func getCafeData() {
        var queue = Int()
        loading(self.view)
        db.collection("cafe").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.cafeArray.removeAll()
            self.currentCafeArray.removeAll()
            for document in querySnapshot!.documents {
                let cafe_id = document.get("cafe_id") as! String
                let booking = document.get("booking") as! Bool
                if booking == true {
                    if document.get("queue") == nil {
                        queue = 0
                    } else {
                        queue = document.get("queue") as! Int
                    }
                    let cafename_en = document.get("cafename_en") as! String
                    let cafename_th = document.get("cafename_th") as! String
                    let area_th = document.get("area_th") as! String
                    let ll_location = document.get("ll_location") as! GeoPoint
                    let (userLocationX, userLocationY) = self.currentLocation()
                    let rawDistance = self.calculateDistance(userLocationX: userLocationX, userLocationY: userLocationY, cafeLocationX: ll_location.latitude, cafeLocationY: ll_location.longitude)
                    let qq = queue
                    let timeArray = document.get("booking_time") as! [String: Any]
                    let today = self.getCurrentWeekday()
                    
                    if timeArray["\(today)"] != nil {
                        let booking_time = timeArray["\(today)"] as! String
                        self.cafeArray.append(CafeQueueData(cafe_id: cafe_id, cafename_en: cafename_en, cafename_th: cafename_th, area_th: area_th, ll_location: ll_location, rawDistance: rawDistance, queue: qq, logoURL: "", booking_time: booking_time))
                    } else {
                        self.cafeArray.append(CafeQueueData(cafe_id: cafe_id, cafename_en: cafename_en, cafename_th: cafename_th, area_th: area_th, ll_location: ll_location, rawDistance: rawDistance, queue: qq, logoURL: "", booking_time: "หยุด"))
                    }
                }
            }
            let dispatch = DispatchGroup()
            self.getLogoImage(allId: self.cafeArray, dispatch: dispatch){ (array) in
                dispatch.notify(queue: .main, execute: {
                    self.cafeArray.removeAll()
                    self.currentCafeArray = array.sorted { $0.rawDistance < $1.rawDistance }
                    self.removeLoading()
                    self.queueListTable.reloadData()
                })
            }
        }
    }
    
    func getLogoImage(allId: [CafeQueueData], dispatch:DispatchGroup, completed: @escaping ([CafeQueueData]) -> Void) {
        let arrayLength = allId.count
        var array = allId
        for n in 0..<arrayLength {
            let id = array[n].cafe_id
            let cafeRef = self.db.collection("cafe_image").document(id)
            dispatch.enter()
            cafeRef.getDocument { (doc, err) in
                if let doc = doc, doc.exists {
                    let imageURL = doc.get("cafe_logo") as! String
                    array[n].logoURL = imageURL
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

}
    
extension QueueListViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentCafeArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 102
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "QueueListCell", for: indexPath) as? QueueListCell else {
            return UITableViewCell()
        }
        let queue = currentCafeArray[indexPath.row]
        cell.cafenameLabel.text = "\(queue.cafename_en) \(queue.cafename_th)"
        cell.areaLabel.text = queue.area_th
        if queue.logoURL == "" {
            cell.logoImage.image = UIImage(named: "background.png")
        } else {
            getData.getImage(imageURL: queue.logoURL, imageView: cell.logoImage)
        }
        let iconImage : UIImage! = UIImage(named: "sandglass.png")
        cell.queueTotalLabel.setImageInLabel(text: "รอ \(queue.queue) คิว", image: iconImage, x: 0, y: -1, width: 13
            , height: 13)
        
        if queue.booking_time == "หยุด" {
            cell.fadeView.isHidden = false
        } else {
            let strArray = queue.booking_time.components(separatedBy: " - ")
            let opening = strArray[0]
            let closing = strArray[1]
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "HH:mm"
            let timeString = formatter.string(from: now)
            
            if timeString >= opening && timeString <= closing {
                if queue.rawDistance/1000 <= 22500.0 {
                    cell.fadeView.isHidden = true
                }
                else {
                    cell.fadeView.isHidden = false
                }
            } else {
                cell.fadeView.isHidden = false
            }
        }
        return cell

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let queue = currentCafeArray[indexPath.row]
        print(queue.rawDistance/1000)
        print("\(queue.cafename_en) \(queue.booking_time)")
        if queue.booking_time == "หยุด" {
            let alert = UIAlertController(title: "วันนี้ร้านหยุดให้บริการ ขออภัยในความไม่สะดวก", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ตกลง", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        } else {
            let strArray = queue.booking_time.components(separatedBy: " - ")
            let opening = strArray[0]
            let closing = strArray[1]
            let now = Date()
            let formatter = DateFormatter()
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "HH:mm"
            let timeString = formatter.string(from: now)
            
            if timeString >= opening && timeString <= closing {
                if queue.rawDistance/1000 <= 22500.0 {
                    let bookQueueVC = storyboard?.instantiateViewController(withIdentifier: "BookQueueVC") as! BookQueueViewController
                    bookQueueVC.delegate = self
                    bookQueueVC.cafeQueueData = queue
                    
                    let navController = UINavigationController(rootViewController: bookQueueVC)
                    bookQueueVC.modalPresentationStyle = .fullScreen
                    navController.modalPresentationStyle = .fullScreen
                    self.present(navController, animated:true, completion: nil)
                }
                else {
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
}

extension QueueListViewController {
    
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
