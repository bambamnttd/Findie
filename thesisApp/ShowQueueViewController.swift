//
//  ShowQueueViewController.swift
//  thesisApp
//
//  Created by Bambam on 30/3/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

protocol BookQueueDelegate : class {
    func bookSuccess(success: Bool)
}

class ShowQueueViewController: UIViewController {

    @IBOutlet weak var queueNumberLabel: UILabel!
    @IBOutlet weak var cafenameLabel: UILabel!
    @IBOutlet weak var cafenameLabel2: UILabel!
    @IBOutlet weak var waitQueueLabel: UILabel!
    @IBOutlet weak var numberPeopleLabel: UILabel!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var iconImage1: UIImageView!
    @IBOutlet weak var iconImage2: UIImageView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var cancelButton2: UIButton!
    @IBOutlet weak var okayButton: UIButton!

    let db = Firestore.firestore()
    var data: MyQueue!
    var queueArray = [Queue]()
    var sortQueueArray = [Queue]()
    let blackColor = UIColor.init(red: 49/255, green: 49/255, blue: 51/255, alpha: 1)
    let redColor = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1)
    let lightGrayColor = UIColor.init(red: 221/255, green: 222/255, blue: 224/255, alpha: 1)
    var from = String()
    var delegate: BookQueueDelegate?
    var waitQueue = UILabel()
    let getData = GetData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
        setupUI()
        
        queueNumberLabel.text = data.queue_no
        numberPeopleLabel.text = "\(data.number_people) คน"
        getCafeData()
        getWaitQueue()
        
        getData.getImage(imageURL: data.logoURL, imageView: logoImage)
        cancelButton.addTarget(self, action: #selector(cancelQueue), for: .touchUpInside)
        cancelButton2.addTarget(self, action: #selector(cancelQueue), for: .touchUpInside)
        okayButton.addTarget(self, action: #selector(goMyQueueVC), for: .touchUpInside)
    }
    
    func setupUI() {
        logoImage.layer.cornerRadius = 5
        okayButton.layer.cornerRadius = 5
        cancelButton.layer.cornerRadius = 5
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = redColor.cgColor
        cancelButton2.layer.cornerRadius = 5
        
        iconImage1.image = iconImage1.image?.withRenderingMode(.alwaysTemplate)
        iconImage1.tintColor = blackColor
        
        iconImage2.image = iconImage2.image?.withRenderingMode(.alwaysTemplate)
        iconImage2.tintColor = blackColor
        
        if from == "MyQueueVC" {
            navigationItem.title = "คิวของฉัน"
            okayButton.isHidden = true
            cancelButton.isHidden = true
            cancelButton2.isHidden = false
        }
        else {
            navigationItem.leftBarButtonItem = UIBarButtonItem()
            navigationItem.title = "คิวของคุณ"
            okayButton.isHidden = false
            cancelButton.isHidden = false
            cancelButton2.isHidden = true
        }
        navigationController?.navigationBar.isTranslucent = false
    }
    
    func getCafeData() {
        let cafeRef = db.collection("cafe").document(data.cafe_id)
        cafeRef.getDocument { (document, err) in
            if let document = document, document.exists {
                let cafename_en = document.get("cafename_en") as! String
                let cafename_th = document.get("cafename_th") as! String
                let area_th = document.get("area_th") as! String
                let pinIcon : UIImage! = UIImage(named: "locationpin.png")
                self.cafenameLabel.text = "\(cafename_en)"
                self.cafenameLabel2.setImageInLabel(text: area_th, image: pinIcon, x: 0, y: -1, width: 13, height: 13)
            }
        }
    }
    
    func getWaitQueue() {
        db.collection("queue").whereField("cafe_id", isEqualTo: data.cafe_id).whereField("status", isEqualTo: "booked")
        .addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.queueArray.removeAll()
            self.sortQueueArray.removeAll()
            for document in documents {
                let queue_no = document.get("queue_no") as! String
                let timeInterval = document.get("timeInterval") as! Double
                let category = String(self.data.queue_no.prefix(1))
                if timeInterval < self.data.timeInterval && queue_no.contains(category) {
                    self.queueArray.append(Queue(queue_no: queue_no, time: timeInterval))
                }
            }
            if self.queueArray.count != 0 {
                print("if")
                self.sortQueueArray = self.queueArray.sorted { $0.time < $1.time }
                self.waitQueueLabel.text = "รออีก \(self.sortQueueArray.count) คิว"
            }
            else {
                print("else")
                self.waitQueueLabel.text = "รออีก 0 คิว"
            }
        }
    }
    
    @objc func cancelQueue() {
        let queue_id = data.queue_id
        db.collection("queue").document(queue_id).delete() { err in
            if let err = err {
                print("Error removing this queue: \(err)")
            } else {
                print("This queue successfully removed!")
                
                let cafe_id = self.data.cafe_id
                self.db.collection("queue").whereField("cafe_id", isEqualTo: cafe_id).whereField("status", isEqualTo: "booked")
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error!)")
                        return
                    }
                    print(documents.count)
                    let cafeRef = self.db.collection("cafe").document(cafe_id)
                    cafeRef.updateData([
                        "queue": documents.count
                    ]) { err in
                        if let err = err {
                            print("Error updating queue to cafe: \(err)")
                        } else {
                            print("Queue successfully updated to cafe")
                        }
                    }
                }
                self.performSegueToReturnBack()
            }
        }
    }
    
    @objc func goMyQueueVC() {
        delegate?.bookSuccess(success: true)
        performSegueToReturnBack()
    }
    
    
    
//    func setBackGroundView() {
//        circleView.layer.cornerRadius = circleView.bounds.height/2
//        ticketView.layer.cornerRadius = 10
//        ticketView.layer.shadowColor = UIColor.gray.cgColor
//        ticketView.layer.shadowOffset = CGSize(width: 2, height: 2)
//        ticketView.layer.shadowRadius = 3.5
//        ticketView.layer.shadowOpacity = 0.4
//        ticketView.layer.shadowPath = UIBezierPath(rect: ticketView.bounds).cgPath
//        ticketView.layer.shouldRasterize = true
//        ticketView.layer.rasterizationScale = UIScreen.main.scale
//    }
}
