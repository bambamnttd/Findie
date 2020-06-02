//
//  CardDetailViewController.swift
//  thesisApp
//
//  Created by Bambam on 18/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

struct Reward {
    var point: Int
    var reward: String
    var imageURL: String
}

class CardDetailViewController: UIViewController {
    
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var bulletTextView: UITextView!
    @IBOutlet weak var collectRewardCollectionView: UICollectionView!
    @IBOutlet weak var collectRewardCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var getRewardCollectionView: UICollectionView!
    @IBOutlet weak var getRewardCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scannerButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var darkView: UIView!
    @IBOutlet weak var cardBackgroundView: UIView!
    @IBOutlet weak var cardBackgroundViewHeight: NSLayoutConstraint!
    @IBOutlet weak var conditionBackgroundView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    
    ///pop up view
    @IBOutlet var popUpView: UIView!
    @IBOutlet weak var rewardLabel: UILabel!
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var rewardImage: UIImageView!
    @IBOutlet weak var getRewardButton: UIButton!
    @IBOutlet weak var popUpBackgroundView: UIView!
    @IBOutlet weak var gifView: UIView!
    @IBOutlet weak var gifImage: UIImageView!
    @IBOutlet weak var rewardLabel2: UILabel!
    @IBOutlet weak var closePopUpButton1: UIButton!
    @IBOutlet weak var closePopUpButton2: UIButton!
    
    let db = Firestore.firestore()
    var cardData : CardCafeListData!
    var rewardArray = [Reward]()
    let getData = GetData()
    let cellIdentifier1 = "CollectRewardCell"
    let cellIdentifier2 = "GetRewardCell"
    var pointArray = [String]()
    var pointArrayInt = [Int]()
    var points = [Int]()
    var maxpoint : Int! = 0
    var userpoint : Int! = 0
    var strings = [String]()
    var collectionViewFlowLayout: UICollectionViewFlowLayout!
    let dispatch = DispatchGroup()
    var cardColor = [String: Float]()
    var selectedIndexPath: IndexPath?
    var opengiftImages = [UIImage]()
    var cafepoint = ""
    let cafepointLabel = UILabel() //เอาไว้เก็บค่า point ที่ได้ของขวัญ ของแต่ละร้าน ออกจากดาต้าเบส
    var cafepointArray = [String]()
    var vSpinner: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        loading(self.view)
        setupNavigationBarItems()
        self.navigationItem.title = cardData.cafename_en
        
        logoImage.layer.cornerRadius = logoImage.bounds.height / 2
        popUpView.layer.cornerRadius = 10
        gifView.layer.cornerRadius = 10
        getRewardButton.layer.cornerRadius = 5
        closePopUpButton2.layer.cornerRadius = 5
        popUpBackgroundView.isHidden = true
        
//        collectRewardCollectionView.backgroundColor = cardColor
        collectRewardCollectionView.backgroundColor = .lightGray
        collectRewardCollectionView.delegate = self
        collectRewardCollectionView.dataSource = self
        getRewardCollectionView.dataSource = self
        getRewardCollectionView.delegate = self
        
        scannerButton.addTarget(self, action: #selector(openQRScanner), for: .touchUpInside)
        getRewardButton.addTarget(self, action: #selector(clickGetReward), for: .touchUpInside)
        closePopUpButton1.addTarget(self, action: #selector(closePopUp), for: .touchUpInside)
        closePopUpButton2.addTarget(self, action: #selector(closePopUp), for: .touchUpInside)
        
        self.rewardLabel2.alpha = 0
        self.closePopUpButton2.alpha = 0
        gifImage.image = UIImage(named: "opengift-15.png")
        gifImage.isHidden = true
        opengiftImages = createImageArray(total: 15, imagePrefix: "opengift")
        
        showData()
        
        if cardData.coverURL != "" {
            let color = cardData.color
            let red = color["red"]!
            let green = color["green"]!
            let blue = color["blue"]!
            collectRewardCollectionView.backgroundColor = UIColor.init(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
        } else {
            collectRewardCollectionView.backgroundColor = .lightGray
        }
        
    }
    
    func showData() {
        nameLabel.text = cardData.cafename_en
        typeLabel.text = cardData.type
        getData.getImage(imageURL: cardData.coverURL, imageView: coverImage)
        getData.getImage(imageURL: cardData.logoURL, imageView: logoImage)
        setBulletLabel()
        getRewardCard()
        getCafeReward()
        getUserPoint()
//        getUserPoint (dispatch: dispatch) {(point) in
//            self.dispatch.notify(queue: .main, execute: {
//                self.userpoint = point
//                self.collectRewardCollectionView.reloadData()
//            })
//        }
    }
    
    ///คำสั่งที่ทำให้ความยาวของ collection view เท่ากับส่วน content
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let getRewardHeight = getRewardCollectionView.collectionViewLayout.collectionViewContentSize.height
        getRewardCollectionViewHeight.constant = getRewardHeight + 10
        print(getRewardCollectionViewHeight.constant)

        collectRewardCollectionView.scrollToItem(at: IndexPath(item: 5, section: 0), at: .bottom, animated: true)
        cardBackgroundViewHeight.constant = collectRewardCollectionViewHeight.constant + 94
        print(cardBackgroundViewHeight.constant)

        let collectRewardHeight = collectRewardCollectionView.collectionViewLayout.collectionViewContentSize.height
        collectRewardCollectionViewHeight.constant = collectRewardHeight
        print(collectRewardHeight)
        
        if conditionBackgroundView.frame.origin.y >= 600 {
            scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: 900)
        }
//        self.view.layoutIfNeeded()
    }
    
    @objc func openQRScanner() {
        let QRScannerVC = storyboard?.instantiateViewController(withIdentifier: "QRScannerVC") as! QRScannerViewController
        QRScannerVC.cardData = cardData
        self.present(QRScannerVC, animated: true)
    }
    
//MARK: - Pop up
    
    @objc func closePopUp() {
        animateOut()
        self.rewardLabel2.alpha = 0
        self.closePopUpButton2.alpha = 0
    }
    
    func createImageArray(total: Int, imagePrefix: String) -> [UIImage] {
        var imageArray = [UIImage]()
        for imageCount in 1...total {
            let imageName = "\(imagePrefix)-\(imageCount).png"
            let image = UIImage(named: imageName)!
            imageArray.append(image)
        }
        return imageArray
    }
    
    func animateIn() {
//        UIApplication.shared.keyWindow!.addSubview(self.popUpBackgroundView)
//        UIApplication.shared.keyWindow!.bringSubviewToFront(self.popUpBackgroundView)
        self.view.addSubview(popUpView)
        popUpView.center = self.backgroundView.center
        popUpView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        popUpView.alpha = 0
        self.popUpBackgroundView.isHidden = true
        self.gifView.isHidden = true
        
        UIView.animate(withDuration: 0.4) {
            self.popUpView.alpha = 1
            self.popUpBackgroundView.isHidden = false
            self.popUpView.transform = CGAffineTransform.identity
        }
    }
        
    func animateOut() {
        UIView.animate(withDuration: 0.3, animations: {
            self.popUpView.alpha = 0
            self.popUpBackgroundView.isHidden = true
            self.popUpView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        }) { (success:Bool) in
            self.popUpView.removeFromSuperview()
        }
    }
    
    func animateImage(imageView: UIImageView, images: [UIImage]) {
        imageView.animationImages = images
        imageView.animationDuration = 1
        imageView.animationRepeatCount = 1
        imageView.startAnimating()
    }
    
    //add uid to get_reward ว่ารับรางวัลนี้ไปแล้ว
    @objc func clickGetReward() {
        let pointText = pointLabel.text!
        let rewardText = rewardLabel.text!
        rewardLabel2.text = rewardText
        print("point = \(pointText)")
        gifView.isHidden = false
        gifImage.isHidden = false
        animateImage(imageView: gifImage, images: opengiftImages)
        
        //animate rewardLabel2
        UIView.animate(withDuration: 0, delay: 1, options: .curveEaseOut, animations: {
            self.rewardLabel2.alpha = 1
        }, completion: { finished in
            print("opened!")
        })
        
        UIView.animate(withDuration: 0, delay: 1.5, options: .curveEaseOut, animations: {
            self.closePopUpButton2.alpha = 1
        })
        
        addToGetReward(pointText: pointText)
        
        //ถ้า point ที่คลิก เท่ากับ point สุดท้ายของกระดาษ จะทำการรีเซ็ต
        if pointText == String(maxpoint) {
            resetUserPoint()
            resetGetReward()
        }
        
    }
    
    ///เพิ่มใน collection -  get reward เพื่อเก็บข้อมูลว่าคนนี้แลกของขวัญไปแล้ว
    func addToGetReward(pointText: String) {
        let cafe_id = cardData.cafe_id
        guard let uid = Auth.auth().currentUser?.uid else { return }
        var ref: DocumentReference? = nil
        ref = db.collection("get_reward").addDocument(data: [
            "cafe_id": cafe_id,
            "uid": uid,
            "point": Int(pointText),
            "createdate": FieldValue.serverTimestamp()
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(ref!.documentID)")
                self.collectRewardCollectionView.reloadData()
            }
        }
        
//        let getRewardRef = db.collection("get_reward").document(cafe_id)
//        let data = [
//            pointText: FieldValue.arrayUnion([uid])
//        ]
//        getRewardRef.updateData(data) { err in
//            if let err = err {
//                print("Error updating document: \(err)")
//            } else {
//                print("Document successfully updated")
//                self.collectRewardCollectionView.reloadData()
//            }
//        }
    }
    
    ///รีเซ็ต uid ใน collection - get reward
    func resetGetReward() {
        let cafe_id = cardData.cafe_id
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("get_reward").whereField("cafe_id", isEqualTo: cafe_id).whereField("uid", isEqualTo: uid).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    self.db.collection("get_reward").document(document.documentID).delete() { err in
                        if let err = err {
                            print("Error removing document: \(err)")
                        } else {
                            print("Document successfully removed!")
                        }
                    }
                }
            }
        }
        
//        let getRewardRef = db.collection("get_reward").document(cafe_id)
//
//        let ppoint = cafepointLabel.text!
//        let ppointArray = convertStringToArray(text: ppoint, separatedBy: " ")
//        print(ppointArray)
//
//        for n in 0..<ppointArray.count {
//            let data = [
//                ppointArray[n] : FieldValue.arrayRemove([uid])
//            ]
//            getRewardRef.updateData(data) { err in
//                if let err = err {
//                    print("Error updating document: \(err)")
//                } else {
//                    print("Remove \(uid) from point \(ppointArray[n]) already")
//                }
//            }
//        }
    }
    
    func convertStringToArray(text stringText: String, separatedBy separator: String) -> [String] {
        var array = stringText.components(separatedBy: separator)
        array.remove(at: array.count-1)
        return array
    }
    
    ///รีเซ็ตคะแนนทั้งหมดให้เป็น 0 เพื่อเริ่มสะสมใหม่ และ reset ใน collection - get_reward ด้วย
    func resetUserPoint() {
        let cafe_id = cardData.cafe_id
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("user").document(uid)
        let type = cardData.type
            
        userRef.getDocument { (document, err) in
            if let document = document, document.exists {
                let membercards = document.get("membercard") as! [[String:Any]]
                for membercard in membercards {
                    if membercard["cafe_id"] as! String == cafe_id {
                        let resetData = [
                            "point": 0,
                            "cafe_id": cafe_id,
                            "type": type,
                            "cafename_en": self.cardData.cafename_en,
                            "createdate": membercard["createdate"] as! Timestamp,
                        ] as [String : Any]
                        
                        //ลบข้อมูลเก่า
                        let deleteData = [
                            "membercard": FieldValue.arrayRemove([membercard])
                        ]
                        userRef.updateData(deleteData) { err in
                            if let err = err {
                                print("Error updating document: \(err)")
                            } else {
                                print("Document successfully updated")
                            }
                        }
                        
                        //reset ให้ point เป็น 0
                        let data = [
                            "membercard": FieldValue.arrayUnion([resetData])
                        ]
                        userRef.updateData(data) { err in
                            if let err = err {
                                print("Error updating document: \(err)")
                            } else {
                                print("Document successfully updated")
                            }
                        }
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }
    
//MARK: - Card detail info
    
    ///ทำให้ข้อมูลตรงเงื่อนไขเป็น list
    func setBulletLabel() {
        let bullet = "•  "
        let cafe_id = cardData.cafe_id
        let cafeRef = db.collection("cafe_reward").document(cafe_id)
        cafeRef.getDocument { (document, err) in
            if let document = document, document.exists && document.get("conditions") != nil {
                let conditions = document.get("conditions") as! [String]
                self.strings = conditions
                self.strings = self.strings.map { return bullet + $0 }
                
                var attributes = [NSAttributedString.Key: Any]()
                attributes[.font] = UIFont(name: "Helvetica Neue", size: 14)
                attributes[.foregroundColor] = UIColor.init(red: 49/255, green: 49/255, blue: 51/255, alpha: 1)
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.headIndent = (bullet as NSString).size(withAttributes: attributes).width
                attributes[.paragraphStyle] = paragraphStyle
                paragraphStyle.paragraphSpacing = 2
                paragraphStyle.lineSpacing = 2
                
                let string = self.strings.joined(separator: "\n")
                self.bulletTextView.attributedText = NSAttributedString(string: string, attributes: attributes)
            }
            else {
                print("Document does not exist")
            }
        }
    }
    
    func getRewardCard() {
        let cafe_id = cardData.cafe_id
        let cafeRef = db.collection("cafe_reward").document(cafe_id)
        cafeRef.getDocument { (document, err) in
            if let document = document, document.exists {
                let reward = document.get("reward") as! [[String:Any]]
                for rw in reward {
                    let point = rw["point"] as! Int
                    self.points.append(point)
                    self.cafepoint += "\(point) "
                }
                self.cafepointLabel.text = self.cafepoint
                self.maxpoint = self.points.max() //เช็คจากใน array ว่าอันไหนมีค่่ามากสุด
                for n in 1...self.maxpoint {
                    let nn = String(n)
//                    if n == self.maxpoint {
//                        nn = "GOAL"
//                    }
                    self.pointArray.append(nn)
                    self.pointArrayInt.append(n)
                }
                self.removeLoading()
                self.collectRewardCollectionView.reloadData()
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func getUserPoint() {
        let cafe_id = cardData.cafe_id
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("user").document(uid)
//        userRef.getDocument { (document, err) in
//            if let document = document, document.exists {
//                let membercards = document.get("membercard") as! [[String:Any]]
//                for membercard in membercards {
//                    if membercard["cafe_id"] as! String == cafe_id {
//                        self.userpoint = membercard["point"] as? Int
//                        print("userpoint = \(self.userpoint)")
//                    }
//                    self.collectRewardCollectionView.reloadData()
//                }
//            } else {
//                print("Document does not exist")
//            }
//        }
        
        userRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
              print("Error fetching document: \(error!)")
              return
            }
            let membercards = document.get("membercard") as! [[String:Any]]
            for membercard in membercards {
                if membercard["cafe_id"] as! String == cafe_id {
                    self.userpoint = membercard["point"] as? Int
                }
                self.collectRewardCollectionView.reloadData()
            }
        }
    }
    
//    func getUserPoint(dispatch:DispatchGroup, completed: @escaping (Int) -> Void) {
//        let cafe_id = cardData.cafe_id
//        let userRef = db.collection("user").document(uid)
//        dispatch.enter()
//        userRef.getDocument { (document, err) in
//            if let document = document, document.exists {
//                let membercards = document.get("membercard") as! [[String:Any]]
//                for membercard in membercards {
//                    for (key1,value1) in membercard {
//                        if key1 == "cafe_id" && value1 as! String == cafe_id {
//                            for (key2,value2) in membercard {
//                                if key2 == "point"{
//                                    self.userpoint = value2 as! Int
//                                }
//                            }
//                        }
//                    }
//                }
//            } else {
//                print("Document does not exist")
//            }
//            dispatch.leave()
//        }
//        dispatch.notify(queue: .main, execute: {
//            completed(self.userpoint)
//        })
//    }
    
    func getCafeReward() {
        let cafe_id = cardData.cafe_id
        let cafeRef = db.collection("cafe_reward").document(cafe_id)
        cafeRef.getDocument { (document, err) in
            if let document = document, document.exists {
                let rewards = document.get("reward") as! [[String:Any]]
                for rw in rewards {
                    let point = rw["point"] as! Int
                    let reward = rw["reward"] as! String
                    let imageURL = rw["reward_imageURL"] as! String
                    self.rewardArray.append(Reward(point: point, reward: reward, imageURL: imageURL))
                    //sort array ให้เรียงจาก point น้อยไปมาก
                    self.rewardArray = self.rewardArray.sorted { $0.point < $1.point }
                }
                self.getRewardCollectionView.reloadData()
                self.collectRewardCollectionView.reloadData()
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func find(value searchValue: String, in array: [String]) -> Bool {
        for value in array {
            if value == searchValue {
                print("เข้า")
                return true
            }
        }
        print("ไม่เข้า")
        return false
    }
    
}

extension CardDetailViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == collectRewardCollectionView {
            return maxpoint
        }
        else {
            return rewardArray.count
        }
    }
    
    //edge inset
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == collectRewardCollectionView {
            return UIEdgeInsets(top: 20, left: 25, bottom: 20, right: 25)
        }
        else {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    //line spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == collectRewardCollectionView {
            return 10
        }
        else {
            return 1
        }
    }
    
    //inter item spacing
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == collectRewardCollectionView {
            let interItemSpacing: CGFloat = 20
            return interItemSpacing
        }
        else {
            return 0
        }
    }
    
    //size of cell
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == collectRewardCollectionView {
            let numberOfItemPerRow: CGFloat = 5
            let interItemSpacing: CGFloat = 20
            let width = (collectRewardCollectionView.frame.width - 40 - 50 - (numberOfItemPerRow * interItemSpacing)) / numberOfItemPerRow
            let height = width
            return CGSize(width: width, height: height)

//            else if maxpoint <= 20 && maxpoint > 10 {
//                let numberOfItemPerRow: CGFloat = 7
//                let interItemSpacing: CGFloat = 10
//                let width = (collectRewardCollectionView.frame.width - 55 - (numberOfItemPerRow * interItemSpacing)) / numberOfItemPerRow
//                let height = width
//                return CGSize(width: width, height: height)
//            }
        }
        else {
            let width = getRewardCollectionView.frame.width
            return CGSize(width: width, height: 72)
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == collectRewardCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier1, for: indexPath) as! CollectRewardCell
            cafepointArray = convertStringToArray(text: cafepointLabel.text!, separatedBy: " ")
            
            if pointArrayInt[indexPath.item] > userpoint {
                print("เข้า if userpoint = \(userpoint)")
                print(pointArrayInt[indexPath.item])
                cell.pointLabel.text = pointArray[indexPath.item]
                cell.giftImage.image = UIImage()
                
                if cafepointArray.contains(pointArray[indexPath.item]) {
                    print("กล่องขาว at \(pointArray[indexPath.item])")
                    cell.pointLabel.text = ""
                    cell.giftImage.image = UIImage(named: "gift_white.png")
                }
            }

            //กลมๆ ตอนที่ยังไม่ได้แต้ม
//            for reward in rewardArray {
//                if pointArrayInt[indexPath.item] == reward.point {
//                    print("pointArrayInt = \(pointArrayInt[indexPath.item]) == \(reward.point)")
//                    cell.pointLabel.text = ""
//                    cell.giftImage.image = UIImage(named: "gift_white.png")
//                }
//            }
                
            //กลมๆ ตอนได้รับแต้ม
            else {
                let uid = Auth.auth().currentUser?.uid
                print("เข้า else userpoint = \(userpoint)")
                cell.backgroundColor = .white
                cell.pointLabel.text = ""
                cell.stampImage.isHidden = false
                cell.stampImage.image = UIImage(named: "star_yellow.png")
                
                if cafepointArray.contains(pointArray[indexPath.item]) {
                    ///เช็คว่ารับของขวัญไปหรือยัง ถ้ารับแล้วจะเป็นกล่องเปิดฝา ถ้ายังกล่องจะปิดฝา
                    let cafe_id = cardData.cafe_id
                    db.collection("get_reward").whereField("cafe_id", isEqualTo: cafe_id).whereField("uid", isEqualTo: uid).getDocuments() { (querySnapshot, err) in
                        if let err = err {
                            print("Error getting documents: \(err)")
                        } else {
                            if querySnapshot!.documents.isEmpty {
                                print("กล่องเขียวปิด at \(self.pointArray[indexPath.item])")
                                cell.stampImage.image = UIImage(named: "gift_green.png")
                            }
                            for document in querySnapshot!.documents {
                                let point = document.get("point") as! Int
                                if point == Int(self.pointArray[indexPath.item]) {
                                    print("กล่องเขียวเปิด at \(self.pointArray[indexPath.item])")
                                    cell.stampImage.image = UIImage(named: "giftopen_green.png")
                                } else {
                                    print("กล่องเขียวปิด at \(self.pointArray[indexPath.item])")
                                    cell.stampImage.image = UIImage(named: "gift_green.png")
                                }
                            }
                        }
                    }
                    

                    
//                    let getRewardRef = db.collection("get_reward").document(cafe_id)
//                    getRewardRef.getDocument { (document, err) in
//                        if let document = document, document.exists {
//                            let uidArray = document.get(self.pointArray[indexPath.item]) as! [String]
//                            if uidArray.contains(uid!) {
//                                print("กล่องเขียวเปิด at \(self.pointArray[indexPath.item])")
//                                cell.stampImage.image = UIImage(named: "giftopen_green.png")
//                            }
//                            else {
//                                print("กล่องเขียว at \(self.pointArray[indexPath.item])")
//                                cell.stampImage.image = UIImage(named: "gift_green.png")
//                            }
//                        } else {
//                            print("Document does not exist")
//                        }
//                    }
                }
            }
//                  else { //กลมๆตอนยังไม่ได้รับแต้ม
//                        cell.backgroundColor = cardColor
//                    }
            
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier2, for: indexPath) as! GetRewardCell
            let reward = rewardArray[indexPath.item].reward
            let point = rewardArray[indexPath.item].point
            let imageURL = rewardArray[indexPath.item].imageURL
            cell.rewardTopic.text = "\(point) แต้ม รับ\(reward)"
            cell.rewardDetail.text = "เมื่อสะสมครบ \(point) แต้ม รับ\(reward)"
            if imageURL == "" {
                let image = cardData.logoURL
                getData.getImage(imageURL: image, imageView: cell.rewardImage)
            }
            else {
                getData.getImage(imageURL: imageURL, imageView: cell.rewardImage)
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        if collectionView == collectRewardCollectionView {
            ///เช็คกับ uid ใน get_reward ถ้ามีอยู่จะทำให้กดรับรางวัลไม่ได้แล้ว
            for reward in rewardArray {
                if self.pointArray[indexPath.item] == "\(reward.point)" && self.userpoint >= reward.point {
                    let cafe_id = cardData.cafe_id
                    db.collection("get_reward").whereField("cafe_id", isEqualTo: cafe_id).whereField("uid", isEqualTo: uid).getDocuments() { (querySnapshot, err) in
                        if let err = err {
                            print("Error getting documents: \(err)")
                        } else {
                            if querySnapshot!.documents.isEmpty {
                                self.animateIn()
                                self.rewardLabel.text = reward.reward
                                self.pointLabel.text = "\(reward.point)"
                                if reward.imageURL == "" {
                                    let image = self.cardData.logoURL
                                    self.getData.getImage(imageURL: image, imageView: self.rewardImage)
                                }
                                else {
                                    self.getData.getImage(imageURL: reward.imageURL, imageView: self.rewardImage)
                                }
                            }
                            for document in querySnapshot!.documents {
                                let point = document.get("point") as! Int
                                if point != Int(self.pointArray[indexPath.item]) {
                                    self.animateIn()
                                    self.rewardLabel.text = reward.reward
                                    self.pointLabel.text = "\(reward.point)"
                                    if reward.imageURL == "" {
                                        let image = self.cardData.logoURL
                                        self.getData.getImage(imageURL: image, imageView: self.rewardImage)
                                    }
                                    else {
                                        self.getData.getImage(imageURL: reward.imageURL, imageView: self.rewardImage)
                                    }
                                }
//                                else if uidd != uid && point != Int(self.pointArray[indexPath.item]) {
//                                    self.animateIn()
//                                    self.rewardLabel.text = reward.reward
//                                    self.pointLabel.text = "\(reward.point)"
//                                    if reward.imageURL == "" {
//                                        let image = self.cardData.logoURL
//                                        self.getData.getImage(imageURL: image, imageView: self.rewardImage)
//                                    }
//                                    else {
//                                        self.getData.getImage(imageURL: reward.imageURL, imageView: self.rewardImage)
//                                    }
//                                }
                            }
                        }
                    }
                    
//                    let getRewardRef = db.collection("get_reward").document(cafe_id)
//                    getRewardRef.getDocument { (document, err) in
//                        if let document = document, document.exists {
//                            let uidArray = document.get("\(reward.point)") as! [String]
//
//                            //ถ้าไม่มี uid ใน get_reward จะให้สามารถกดรับกล่องของขวัญได้
//                            if !uidArray.contains(uid) {
//                                self.animateIn()
//                                self.rewardLabel.text = reward.reward
//                                self.pointLabel.text = "\(reward.point)"
//                                if reward.imageURL == "" {
//                                    let image = self.cardData.logoURL
//                                    self.getData.getImage(imageURL: image, imageView: self.rewardImage)
//                                }
//                                else {
//                                    self.getData.getImage(imageURL: reward.imageURL, imageView: self.rewardImage)
//                                }
//                            }
//                        } else {
//                            print("Document does not exist")
//                        }
//                    }
                }
            }
        }
    }
}

extension CardDetailViewController {
    
    func loading(_ uiView: UIView) {
        var container: UIView = UIView()
        container.frame = uiView.frame
        container.center = uiView.center
        container.backgroundColor = .white
        
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
            container.addSubview(loadingView)
            uiView.addSubview(container)
        }
        vSpinner = container
        activity.startAnimating()
    }
    
    func removeLoading() {
        DispatchQueue.main.async {
            self.vSpinner?.removeFromSuperview()
            self.vSpinner = nil
        }
    }
}
