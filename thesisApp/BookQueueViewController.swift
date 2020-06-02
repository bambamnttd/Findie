//
//  BookQueueViewController.swift
//  thesisApp
//
//  Created by Bambam on 23/3/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

extension BookQueueViewController: BookQueueDelegate {
    func bookSuccess(success: Bool) {
        self.success = success
    }
}

struct Queue {
    var queue_no: String
    var time: Double
}

class BookQueueViewController: UIViewController {
    
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var tableImage: UIImageView!
    @IBOutlet weak var cafenameLabel: UILabel!
    @IBOutlet weak var waitQueueLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minusButton: UIButton!
    @IBOutlet weak var bookButton: UIButton!
    @IBOutlet weak var contactButton: UIButton!
    
    let db = Firestore.firestore()
    var number = 1
    var cafeQueueData: CafeQueueData!
    var queueDataArray = [Queue]()
    var sortedArray = [Queue]()
    var getData = GetData()
    let redColor = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1)
    let blackColor = UIColor.init(red: 49/255, green: 49/255, blue: 51/255, alpha: 1)
    let personIcon : UIImage! = UIImage(named: "person1.png")
    let sandglassIcon : UIImage! = UIImage(named: "sandglass.png")
    var delegate: BookQueueDelegate?
    var success = false
    var vSpinner: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        
        getData.getImage(imageURL: cafeQueueData.logoURL, imageView: logoImage)
        cafenameLabel.text = cafeQueueData.cafename_en
        waitQueueLabel.setImageInLabel(text: "รอ 0 คน", image: sandglassIcon, x: 0, y: -1, width: 13, height: 13)
        
        tableImage.image = UIImage(named: "table-1")
    
        getWaitQueue()
        
        amountLabel.setImageInLabel(text: "\(number) ท่าน", image: personIcon, x: 0, y: -1, width: 24, height: 24)
        
        plusButton.addTarget(self, action: #selector(plus), for: .touchUpInside)
        minusButton.addTarget(self, action: #selector(minus), for: .touchUpInside)
        bookButton.addTarget(self, action: #selector(bookQueue), for: .touchUpInside)
        contactButton.addTarget(self, action: #selector(contactCafe), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("เข้าหรือไม่ \(success)")
        if success == true {
            //เปลี่ยนไป tab my queue
//            self.tabBarController?.selectedIndex = 2
//            let navVC = tabBarController?.viewControllers![2] as! UINavigationController
//            let myQueueVC = navVC.topViewController as! MyQueueViewController
            delegate?.bookSuccess(success: true)
            self.dismiss(animated: true, completion: nil)
            success = false
        }
        
    }
    
    func setup() {
        logoImage.layer.cornerRadius = logoImage.bounds.height/2
        
        plusButton.layer.cornerRadius = plusButton.bounds.height/2
        plusButton.backgroundColor = redColor
        plusButton.tintColor = .white
        
        minusButton.tintColor = redColor
        minusButton.layer.cornerRadius = plusButton.bounds.height/2
        minusButton.layer.borderWidth = 1
        minusButton.layer.borderColor = redColor.cgColor
        
//        bookButton.layer.cornerRadius = 5
        bookButton.setTitle("จองเลย", for: .normal)
        
        navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        navigationController?.navigationBar.setBackgroundImage(UIColor.clear.as1ptImage(), for: .default)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: blackColor]
        
        let closeButton = UIButton()
        closeButton.setImage(UIImage(named: "close_red.png"), for: .normal)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        closeButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            
        let menuBarItem = UIBarButtonItem(customView: closeButton)
        let currWidth = menuBarItem.customView?.widthAnchor.constraint(equalToConstant: 20)
        let currHeight = menuBarItem.customView?.heightAnchor.constraint(equalToConstant: 20)
        currWidth?.isActive = true
        currHeight?.isActive = true
        
        navigationItem.rightBarButtonItem = menuBarItem
        navigationItem.title = "\(cafeQueueData.cafename_en) \(cafeQueueData.area_th)"
    }
    
    @objc func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func plus() {
        if number < 8 {
            number+=1
            amountLabel.setImageInLabel(text: "\(number) ท่าน", image: personIcon, x: 0, y: -1, width: 24, height: 24)
            tableImage.image = UIImage(named: "table-\(number)")
        }
    }
    
    @objc func minus() {
        if number > 1 {
            number-=1
            amountLabel.setImageInLabel(text: "\(number) ท่าน", image: personIcon, x: 0, y: -1, width: 24, height: 24)
            tableImage.image = UIImage(named: "table-\(number)")
        }
    }
    
    @objc func contactCafe() {
        let cafe_id = cafeQueueData.cafe_id
        let data = db.collection("cafe").document(cafe_id)
        data.getDocument { (document, err) in
            if let document = document, document.exists {
                let tel = document.get("cafe_tel") as! [String]
                let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                for phoneNumber in tel {
                    let phoneCallAction = UIAlertAction(title: phoneNumber, style: .default) { (action) in
                        if let url = URL(string: "tel://\(phoneNumber)"),
                        UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }
                    optionMenu.addAction(phoneCallAction)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                optionMenu.addAction(cancelAction)
                self.present(optionMenu, animated: true, completion: nil)
            }
            else {
                print("Document does not exist")
            }
        }
    }
    
    @objc func bookQueue() {
        if Auth.auth().currentUser != nil {
            addBooking()
        } else {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
            vc.from = "BookQueueVC"
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func addBooking() {
        print(number)
//        var categoryArray = [String]()
        var queue_no = String()
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let cafe_id = cafeQueueData.cafe_id
        let cafename_en = cafeQueueData.cafename_en
        let category = tableCategory(number: number)
        
        //เช็คว่าเคยจองไปยังร้านนี้ ถ้าจองแล้วจะไม่ให้จองซ้ำ
        loading(self.view)
        db.collection("queue").whereField("cafe_id", isEqualTo: cafe_id).whereField("uid", isEqualTo: uid).whereField("status", isEqualTo: "booked").getDocuments() { (query, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                print("query!.documents.count \(query!.documents.count)")
                if query!.documents.count == 0 {
                    self.db.collection("queue").whereField("cafe_id", isEqualTo: cafe_id).getDocuments() { (querySnapshot, err) in
                        if let err = err {
                            print("Error getting documents: \(err)")
                        } else {
                            if querySnapshot!.documents.count != 0 { //ข้อมูลไม่เท่ากับ 0
                                for document in querySnapshot!.documents {
                                    let cate = document.get("queue_no") as! String
                                    let time = document.get("timeInterval") as! Double
                                    if cate.contains(category) { //มี A B C D อยู่ใน string
                                        self.queueDataArray.append(Queue(queue_no: cate, time: time))
                                    }
                                }
                                if self.queueDataArray.count != 0 { //มี A B C D อยู่ใน string ค่าใน array ไม่เท่ากับ 0
                                    self.sortedArray = self.queueDataArray.sorted { $0.time < $1.time }
                                    let last = self.sortedArray.last!
                                    print("last of category = \(last)")
                                    let seperateLast = last.queue_no.components(separatedBy: category)
                                    var last_no = Int(seperateLast[1])!
                                    if last_no == 99 { //ถ้าบัตรคิวถึงเลข 99 อันต่อไปจะเซ็ตให้กลับไปเป็น 0
                                        last_no = 0
                                    }
                                    queue_no = "\(category)\(String(format: "%02d", last_no+1))"
                                    print(queue_no)
                                }
                                else { //ไม่มี A B C D อยู่ใน string ค่าใน array เป็น 0
                                    print("ไม่มีคิวที่มี \(category) นำหน้า")
                                    queue_no = "\(category)01"
                                    print(queue_no)
                                }
                            }
                            else { //ยังไม่มีคิวของร้านคาเฟ่นี้ๆ
                                print("ไม่มีคิวเลย")
                                queue_no = "\(category)01"
                                print(queue_no)
                            }
                            let time = Date().timeIntervalSinceReferenceDate
                            let data = [
                                "queue_no": queue_no,
                                "uid": uid,
                                "cafe_id": cafe_id,
                                "cafename_en": cafename_en,
                                "number_people": self.number,
                                "createdate": FieldValue.serverTimestamp(),
                                "timeInterval": time,
                                "status": "booked"
                            ] as [String : Any]

                            //add queue data to collection-queue
                            var ref: DocumentReference? = nil
                            ref = self.db.collection("queue").addDocument(data: data) { errr in
                                if let errr = errr {
                                    print("Error adding queue: \(errr)")
                                } else {
                                    print("Queue added with ID: \(ref!.documentID)")
                                    
                                    let queueData = MyQueue(
                                        queue_id: ref!.documentID,
                                        queue_no: queue_no,
                                        number_people: self.number,
                                        wait_queue: 0,
                                        cafe_id: cafe_id,
                                        logoURL: self.cafeQueueData.logoURL,
                                        timeInterval: time,
                                        status: "booked")
                                            
                                    let queueRef = self.db.collection("queue").document(ref!.documentID)
                                    queueRef.updateData([
                                        "queue_id" : "\(ref!.documentID)"
                                    ]) { er in
                                        if let er = er {
                                            print("Error updating queue: \(er)")
                                        } else {
                                            print("Queue successfully updated")
                                            self.addQueueToCafeData()
                                            let showQueueVC = self.storyboard?.instantiateViewController(withIdentifier: "ShowQueueVC") as! ShowQueueViewController
                                            showQueueVC.data = queueData
                                            showQueueVC.from = "BookQueueVC"
                                            showQueueVC.delegate = self
                                            self.removeLoading()
                                            self.navigationController?.pushViewController(showQueueVC, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    self.removeLoading()
                    let alert = UIAlertController(title: "ไม่สามารถจองคิวซ้ำได้", message: "ยกเลิกคิวก่อนหน้านี้ แล้วค่อยจองใหม่นะ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "ตกลง", style: .cancel, handler: nil))
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    func tableCategory(number: Int) -> String {
        var category = ""
        if number <= 2 {
            category = "A"
        }
        else if number > 2 && number <= 4 {
            category = "B"
        }
        else if number > 4 && number <= 6 {
            category = "C"
        }
        else {
            category = "D"
        }
        return category
    }
    
    func getWaitQueue() {
        db.collection("queue").whereField("cafe_id", isEqualTo: cafeQueueData.cafe_id).whereField("status", isEqualTo: "booked")
        .addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            self.waitQueueLabel.setImageInLabel(text: "รอ \(documents.count) คน", image: self.sandglassIcon, x: 0, y: -1, width: 13, height: 13)
        }
    }
    
    func addQueueToCafeData() {
        let cafe_id = cafeQueueData.cafe_id
        db.collection("queue").whereField("cafe_id", isEqualTo: cafe_id).whereField("status", isEqualTo: "booked").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
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
    }
}

extension BookQueueViewController {
    
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
