//
//  ShowReviewViewController.swift
//  thesisApp
//
//  Created by Bambam on 23/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

struct ImageURL {
    var id : String
    var imageURL : String
}

extension ShowReviewViewController: AlertDelegate {
    func presentAlert(review_id: String, cafe_id: String) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "ยกเลิก", style: .cancel)
        let deleteAction = UIAlertAction(title: "ลบ", style: .destructive) { (action) in
            let alert = UIAlertController(title: "คุณแน่ใจแล้วว่าต้องการลบความคิดเห็นนี้", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ยกเลิก", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "ใช่", style: .destructive) { (action) in
                self.db.collection("review").document(review_id).delete() { err in
                    if let err = err {
                        print("Error removing document: \(err)")
                    } else {
                        self.getData.calculateRating(cafe_id: cafe_id)
                        print("Document successfully removed!")
                    }
                }
            })
            self.present(alert, animated: true)
        }
        optionMenu.addAction(cancelAction)
        optionMenu.addAction(deleteAction)
        self.present(optionMenu, animated: true, completion: nil)
    }
}

class ShowReviewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var cafeData: CafeData!
    var from : String!
    let cellId = "ShowReviewCollectionViewCell"
    let db = Firestore.firestore()
    let getData = GetData()
    var reviewArray = [ReviewData]()
    var imageURL = [ImageURL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = UIColor.init(red: 240/255, green: 240/255, blue: 241/255, alpha: 1)
        setupNavigationBarItems()
        navigationController?.navigationBar.isTranslucent = false
        
        if from == "cafeDetailVC" {
            navigationItem.title = "รีวิว"
        }
        else {
            navigationItem.title = "รีวิวของฉัน"
        }
        
        setupCollectionView()
        getDataReview()
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        let nib = UINib(nibName: "ShowReviewCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellId)
    }
    
    public func getDataReview() {
        if from == "cafeDetailVC" {
            let reviewRef = self.db.collection("review").order(by: "time", descending: true)
            reviewRef.getDocuments { (snapshot, error) in
                if error == nil && snapshot != nil {
                    self.reviewArray.removeAll()
                    for doc in snapshot!.documents {
                        let cafe_id = doc.get("cafe_id") as! String
                        let cafename_en = doc.get("cafename_en") as! String
                        if self.cafeData.cafe_id == cafe_id {
                            let uid = doc.get("uid") as! String
                            let username = doc.get("username") as! String
                            let rating = doc.get("rating") as! Float
                            let timeInterval = doc.get("timeInterval") as! TimeInterval
                                    
                            let review_text = doc.get("review_text") as! String
                                    
                            self.imageURL.append(ImageURL(id: uid, imageURL: ""))
                            self.reviewArray.append(ReviewData(review_id: doc.documentID, username: username, cafename_en: cafename_en, cafe_id: cafe_id, rating: rating, timeInterval: timeInterval, review_text: review_text))
                        }
                    }
                    let dispatch = DispatchGroup()
                    self.getImageURL(allId: self.imageURL, dispatch: dispatch){(array) in
                        dispatch.notify(queue: .main, execute: {
                            self.imageURL.removeAll()
                            self.imageURL = array
                            self.collectionView.reloadData()
                        })
                    }
                }
            }
        }
        else {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let reviewRef = self.db.collection("review").whereField("uid", isEqualTo: uid)
            reviewRef.addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                self.reviewArray.removeAll()
                for doc in documents {
                    let cafe_id = doc.get("cafe_id") as! String
                    let cafename_en = doc.get("cafename_en") as! String
                    let username = doc.get("username") as! String
                    let rating = doc.get("rating") as! Float
                    let timeInterval = doc.get("timeInterval") as! TimeInterval
                    let review_text = doc.get("review_text") as! String
                    
                    self.imageURL.append(ImageURL(id: uid, imageURL: ""))
                    self.reviewArray.append(ReviewData(review_id: doc.documentID, username: username, cafename_en: cafename_en, cafe_id: cafe_id, rating: rating, timeInterval: timeInterval, review_text: review_text))
                    self.reviewArray = self.reviewArray.sorted { $0.timeInterval > $1.timeInterval}
                }
                let dispatch = DispatchGroup()
                self.getImageURL(allId: self.imageURL, dispatch: dispatch){(array) in
                    dispatch.notify(queue: .main, execute: {
                        self.imageURL.removeAll()
                        self.imageURL = array
                        self.collectionView.reloadData()
                    })
                }
            }
            
        }
    }
    
    ///เวลาเราจะดึงข้อมูลจาก firestore พอเก็บเข้า array มันจะไม่เรียงให้ตามที่เราต้องการ ก็เลยต้องมีตัวกำกับหนึ่งอัน อย่าง userid: แล้วก็อยากจะเพิ่มค่าอะไรก็เพิ่มในเข้าไปในตัวที่สอง ก็คือ imageURL : เพิ่มเข้าไปตรงๆแทนการ append เพราะ append แล้วเละค่ะมันไม่เรียงให้น้องค่ะ
    public func getImageURL(allId: [ImageURL], dispatch:DispatchGroup, completed: @escaping ([ImageURL]) -> Void) {
        let arrayLength = allId.count
        var array = allId
        for n in 0..<arrayLength {
            let id = array[n].id
            let user = db.collection("user").document(id)
            dispatch.enter()
            user.getDocument { (document, err) in
                if let document = document, document.exists {
                    let uurl = document.get("user_imageURL") as! String
                    array[n].imageURL = uurl
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
    
    public func changeAllStarRateToImage(rating : Float) -> UIImage {
        var rateImage = UIImage()
        switch rating {
        case 1.0:
            rateImage = UIImage(named: "star11.png")!
            return rateImage
        case 2.0:
            rateImage = UIImage(named: "star22.png")!
            return rateImage
        case 3.0:
            rateImage = UIImage(named: "star33.png")!
            return rateImage
        case 4.0:
            rateImage = UIImage(named: "star44.png")!
            return rateImage
        default:
            rateImage = UIImage(named: "star55.png")!
            return rateImage
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return reviewArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let user = reviewArray[indexPath.item] as? ReviewData {
            let approximateWidthOfReviewTextView = view.frame.width - 78
            let size = CGSize(width: approximateWidthOfReviewTextView, height: 1000)
            let attributes = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15)]
            let estimatedFrame = NSString(string: user.review_text).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            return CGSize(width: view.frame.width, height: estimatedFrame.height + 85)
        }
        return CGSize(width: view.frame.width, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? ShowReviewCollectionViewCell else {
            return UICollectionViewCell()
        }
        let username = reviewArray[indexPath.item].username
        let cafename_en = reviewArray[indexPath.item].cafename_en
        cell.textReview.text = reviewArray[indexPath.item].review_text
        cell.starRate.image = changeAllStarRateToImage(rating: reviewArray[indexPath.item].rating)
        
        //format date
        let timeFormat = DateFormatter()
        timeFormat.dateFormat = "MMM d, HH:mm"
        let timestamp = timeFormat.string(from: Date(timeIntervalSinceReferenceDate: reviewArray[indexPath.item].timeInterval))
        cell.timeReview.text = timestamp
        
        if from == "cafeDetailVC" {
            cell.userName.text = username
            cell.moreButton.isHidden = true
        }
        else {
            cell.userName.text = "\(username) รีวิว \(cafename_en)"
            cell.data = reviewArray[indexPath.item]
            cell.alertDelegate = self
            cell.moreButton.isHidden = false
        }
        
        if imageURL[indexPath.item].imageURL != "" {
            let storageRef = Storage.storage().reference(forURL: imageURL[indexPath.item].imageURL)
            cell.userImage.sd_setImage(with: storageRef)
        }
        else {
            cell.userImage.image = UIImage(named: "profile.png")
        }
        return cell
    }

}
