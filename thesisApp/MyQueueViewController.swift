//
//  BookingViewController.swift
//  thesisApp
//
//  Created by Bambam on 4/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import AudioToolbox

struct MyQueue {
    var queue_id: String
    var queue_no: String
    var number_people: Int
    var wait_queue: Int
    var cafe_id: String
    var logoURL: String
    var timeInterval: Double
    var status: String
}

struct LogoURL {
    var cafe_id: String
    var logoURL: String
}

class MyQueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var myQueueTable: UITableView!
    @IBOutlet weak var noBookingImage: UIImageView!
    @IBOutlet weak var noBookingLabel: UILabel!
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var popupBackgroundView: UIView!
    @IBOutlet weak var queueNumberLabel: UILabel!
    @IBOutlet weak var closePopupButton: UIButton!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    
    let db = Firestore.firestore()
    var queueArray = [MyQueue]()
    var currentQueueArray = [MyQueue]()
    var logoURL = [LogoURL]()
    let getData = GetData()
    var count = 0
    var cc = 0
    var newQueue = false
    let blackColor = UIColor.init(red: 49/255, green: 49/255, blue: 51/255, alpha: 1)
    var vSpinner: UIView?
    
    func notification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound])
            { (didAllow, error) in
                if !didAllow {
                    print("User has declined notifications")
                }
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Hello"
        content.body = "ใกล้จะถึงคิวของคุณแล้ว"
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        navigationController?.navigationBar.setBackgroundImage(UIColor.white.as1ptImage(), for: .default)
        navigationItem.title = "คิวของฉัน"
        closePopupButton.addTarget(self, action: #selector(closePopup), for: .touchUpInside)
        
        myQueueTable.delegate = self
        myQueueTable.dataSource = self
        popupBackgroundView.isHidden = true
        
        loginButton.layer.cornerRadius = 5
        
        if Auth.auth().currentUser != nil {
            loginView.isHidden = true
            getUserQueue()
//            notification()
        } else {
            loginView.isHidden = false
            loginButton.addTarget(self, action: #selector(openVC), for: .touchUpInside)
        }
    }
    
    @objc func openVC() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
        vc.from = "MyQueueVC"
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func closePopup() {
        animateOut()
    }
    
    func animateIn() {
        popupView.layer.cornerRadius = 10
        popupView.layer.shadowColor = UIColor.gray.cgColor
        popupView.layer.shadowOffset = CGSize(width: 2, height: 2)
        popupView.layer.shadowRadius = 10
        popupView.layer.shadowOpacity = 0.4
        self.view.addSubview(popupView)
        popupView.center = self.view.center
        popupView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        popupView.alpha = 0
        self.popupBackgroundView.isHidden = true
        
        UIView.animate(withDuration: 0.4) {
            self.popupView.alpha = 1
            self.popupBackgroundView.isHidden = false
            self.popupView.transform = CGAffineTransform.identity
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            
            if let tabItems = self.tabBarController?.tabBar.items {
                let tabItem = tabItems[2]
                tabItem.badgeValue = "1"
            }
        }
    }
            
    func animateOut() {
        UIView.animate(withDuration: 0.3, animations: {
            if let tabItems = self.tabBarController?.tabBar.items {
                let tabItem = tabItems[2]
                tabItem.badgeValue = nil
            }
            self.popupView.alpha = 0
            self.popupBackgroundView.isHidden = true
            self.popupView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        }) { (success:Bool) in
            self.popupView.removeFromSuperview()
        }
    }
    
    func getUserQueue() {
        loading(self.view)
        var waitQueue = 0
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("queue").order(by: "createdate", descending: true).addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.queueArray.removeAll()
            self.cc = 0
            for document in documents {
                let uuid = document.get("uid") as! String
                if uuid == uid {
                    self.cc += 1
                    let queue_id = document.documentID
                    let queue_no = document.get("queue_no") as! String
                    let cafe_id = document.get("cafe_id") as! String
                    let number_pp = document.get("number_people") as! Int
                    let timeInterval = document.get("timeInterval") as! Double
                    let status = document.get("status") as! String
                    let category = String(queue_no.prefix(1))
                    
                    print("\(self.cc) - \(cafe_id) \(queue_no)")
                    if status == "booked" {
                        waitQueue = self.getWaitQueue(documents: documents, timeInterval: timeInterval, category: category, cafe_id: cafe_id)
                    }
                    else {
                        waitQueue = 0
                    }
                    if status != "done" {
                        self.queueArray.append(MyQueue(queue_id: queue_id, queue_no: queue_no, number_people: number_pp, wait_queue: waitQueue, cafe_id: cafe_id, logoURL: "", timeInterval: timeInterval, status: status))
                    }
                }
            }
            print("queueArray = \(self.queueArray.count)")
            if self.queueArray.count > 0 {
                self.myQueueTable.isHidden = false
                let dispatch = DispatchGroup()
                self.getLogoURL(allCafeid: self.queueArray, dispatch: dispatch) {(array) in
                    dispatch.notify(queue: .main, execute: {
                        self.queueArray = array
                        self.currentQueueArray = self.queueArray.sorted { $0.timeInterval > $1.timeInterval }
                        self.removeLoading()
                        self.myQueueTable.reloadData()
                    })
                }
            }
            else {
                self.removeLoading()
                self.myQueueTable.isHidden = true
            }
        }
    }
    
    func getWaitQueue(documents: [QueryDocumentSnapshot], timeInterval: Double, category: String, cafe_id: String) -> Int {
        count = 0
        for doc in documents {
            let c_id = doc.get("cafe_id") as! String
            let time = doc.get("timeInterval") as! Double
            let q_no = doc.get("queue_no") as! String
            let status = doc.get("status") as! String
            if c_id == cafe_id && q_no.contains(category) && status == "booked"{
                if time < timeInterval {
                    print("category = \(category)")
                    count += 1
                }
            }
        }
        print(count)
        return count
    }
    
    func getLogoURL(allCafeid: [MyQueue], dispatch:DispatchGroup, completed: @escaping ([MyQueue]) -> Void) {
        let arrayLength = allCafeid.count
        var array = allCafeid
        for n in 0..<arrayLength {
            let cafe_id = array[n].cafe_id
            let cafeImg = db.collection("cafe_image").document(cafe_id)
            dispatch.enter()
            cafeImg.getDocument { (document, err) in
                if let document = document, document.exists {
                    let url = document.get("cafe_logo") as! String
                    array[n].logoURL = url
                } else {
                    print("Document does not exist")
                }
                dispatch.leave()
            }
        }
        dispatch.notify(queue: .main, execute: {
            completed(array)
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentQueueArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 124
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MyQueueCell", for: indexPath) as? MyQueueCell else {
            return UITableViewCell()
        }
        let queueData = currentQueueArray[indexPath.row]
        cell.queueNumberLabel.text = queueData.queue_no
        getData.getImage(imageURL: queueData.logoURL, imageView: cell.logoImage)
        
        if queueData.status == "booked" {
            cell.ticketImage.image = UIImage(named: "ticket-mini.png")
            cell.queueTitleLabel.textColor = blackColor
            cell.queueNumberLabel.textColor = blackColor
            cell.waitTitleLabel.textColor = .white
            cell.waitTitleLabel.text = "รออีก"
            cell.waitQueueLabel.text = "\(queueData.wait_queue)"
            cell.fadeView.isHidden = true
        }
        else if queueData.status == "called" {
            cell.ticketImage.image = UIImage(named: "ticket-mini.png")
            cell.queueTitleLabel.textColor = blackColor
            cell.queueNumberLabel.textColor = blackColor
            cell.waitTitleLabel.textColor = .white
            cell.waitTitleLabel.text = "ถึงคิวคุณแล้ว"
            cell.waitQueueLabel.text = "\(queueData.wait_queue)"
            cell.fadeView.isHidden = true
            let cancelIcon: UIImage! = UIImage(named: "called.png")
            cell.waitQueueLabel.setImageInLabel(text: "", image: cancelIcon, x: 0, y: 0, width: 34, height: 34)
        }
        else if queueData.status == "passed" {
            cell.ticketImage.image = UIImage(named: "ticketCancel-mini.png")
            cell.queueTitleLabel.textColor = .white
            cell.queueNumberLabel.textColor = .white
            cell.waitTitleLabel.textColor = .white
            cell.waitTitleLabel.text = "คิวถูกยกเลิก"
            let cancelIcon: UIImage! = UIImage(named: "cancel.png")
            cell.waitQueueLabel.setImageInLabel(text: "", image: cancelIcon, x: 0, y: 0, width: 34, height: 34)
            cell.fadeView.isHidden = false
            animateOut()
            print("คิวของคุณถูกยกเลิก")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let showQueueVC = self.storyboard?.instantiateViewController(withIdentifier: "ShowQueueVC") as! ShowQueueViewController
        let queueData = currentQueueArray[indexPath.row]
        
        if queueData.status == "booked" {
            showQueueVC.data = queueData
            showQueueVC.from = "MyQueueVC"
            self.navigationController?.pushViewController(showQueueVC, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let queueData = currentQueueArray[indexPath.row]
        if queueData.status == "called" {
            queueNumberLabel.text = queueData.queue_no
            animateIn()
        }
    }
}

extension MyQueueViewController {
    
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

