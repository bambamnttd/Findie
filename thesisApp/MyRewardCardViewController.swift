//
//  MyRewardCardViewController.swift
//  thesisApp
//
//  Created by Bambam on 22/4/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

class MyRewardCardViewController: UIViewController {
    
    @IBOutlet weak var rewardCardTable: UITableView!

    let db = Firestore.firestore()
    var cardArray = [CardCafeListData]()
    var currentCardArray = [CardCafeListData]()
    let getData = GetData()
    var vSpinner: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loading(self.view)
        rewardCardTable.delegate = self
        rewardCardTable.dataSource = self
        setupNavigationBarItems()
        navigationItem.title = "บัตรสะสมแต้ม"
        getMemberCard()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        self.tabBarController?.tabBar.isHidden = true
//    }
//
//    override func viewWillDisappear(_ animated: Bool){
//        self.tabBarController?.tabBar.isHidden = false
//    }
    
    func getMemberCard() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("user").document(uid).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            self.cardArray.removeAll()
            self.currentCardArray.removeAll()
            let membercards = document.get("membercard") as! [[String:Any]]
            for membercard in membercards {
                let cafeid = membercard["cafe_id"] as! String
                let cafename_en = membercard["cafename_en"] as! String
                let type = membercard["type"] as! String
                let createdate = membercard["createdate"] as! Timestamp
                let point = membercard["point"] as! Int
                    
                self.cardArray.append(CardCafeListData(cafe_id: cafeid, cafename_en: cafename_en, type: type, user_point: point, total_point: 0, logoURL: "", coverURL: "", createdate: createdate, exp_date: "", color: [:]))
            }
                
            let dispatch = DispatchGroup()
            self.getCafeImage(allCafe: self.cardArray, dispatch: dispatch) {(arrayImage) in
                dispatch.notify(queue: .main, execute: {
                    self.getExpirationDate(allCard: self.cardArray, dispatch: dispatch) {(array) in
                        dispatch.notify(queue: .main, execute: {
                            self.currentCardArray = array.sorted {$0.createdate.dateValue() > $1.createdate.dateValue() }
                            self.removeLoading()
                            self.rewardCardTable.reloadData()
                        })
                    }
                })
            }
        }
    }
        
    func getCafeImage(allCafe: [CardCafeListData], dispatch:DispatchGroup, completed: @escaping ([CardCafeListData]) -> Void) {
        let arrayLength = allCafe.count
        var array = allCafe
        for n in 0..<arrayLength {
            let cafe_id = array[n].cafe_id
            let cafeImageRef = db.collection("cafe_image").document(cafe_id)
            dispatch.enter()
            cafeImageRef.getDocument { (document, err) in
                if let document = document, document.exists {
                    let logoURL = document.get("cafe_logo") as! String
                    let coverURL = document.get("cafe_cover") as! String
                    array[n].logoURL = logoURL
                    array[n].coverURL = coverURL
                    if coverURL != "" {
                        let color = document.get("cafe_color") as! [String: Float]
                        array[n].color = color
                    }
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
        
    func getExpirationDate(allCard: [CardCafeListData], dispatch:DispatchGroup, completed: @escaping ([CardCafeListData]) -> Void) {
        var pointArray = [Int]()
        let arrayLength = allCard.count
        var array = allCard
        for n in 0..<arrayLength {
            let cafe_id = array[n].cafe_id
            let cafe_rewardRef = db.collection("cafe_reward").document(cafe_id)
            dispatch.enter()
            cafe_rewardRef.getDocument { (document, err) in
                if let document = document, document.exists {
                    let rewards = document.get("reward") as! [[String:Any]]
                    for reward in rewards {
                        let point = reward["point"] as! Int
                        pointArray.append(point)
                    }
                    let total_point = pointArray.max()!
                    array[n].total_point = total_point
                    array[n].exp_date = ""
                    if document.get("exp_date") != nil {
                        let exp_date = document.get("exp_date") as! Timestamp
                        let timeFormat = DateFormatter()
                        timeFormat.dateFormat = "dd MMM yy"
                        let timestamp = timeFormat.string(from: exp_date.dateValue())
                        array[n].exp_date = timestamp
                    }
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

}

extension MyRewardCardViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentCardArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 240
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = rewardCardTable.dequeueReusableCell(withIdentifier: "cardcell", for: indexPath) as? CardListCell else {
            return UITableViewCell()
        }
        let card = currentCardArray[indexPath.row]
        cell.nameLabel.text = card.cafename_en
        cell.typeLabel.text = card.type
        cell.pointLabel.text = "\(card.user_point)/\(card.total_point)"
        if card.exp_date == "" {
            cell.expDateLabel.setImageInLabel(text: "ไม่มีวันหมดอายุ", image: UIImage(named: "clock.png")!, x: 0, y: -2, width: 11, height: 11)
        }
        else {
            cell.expDateLabel.setImageInLabel(text: "หมดอายุวันที่ \(card.exp_date)", image: UIImage(named: "clock.png")!, x: 0, y: -2, width: 11, height: 11)
        }
        
        if card.logoURL != "" {
            getData.getImage(imageURL: card.logoURL, imageView: cell.logoImage)
        } else {
            cell.logoImage.image = UIImage(named: "background.png")
        }
        
        if card.coverURL != "" {
            getData.getImage(imageURL: card.coverURL, imageView: cell.cardImage)
            let color = card.color
            let red = color["red"]!
            let green = color["green"]!
            let blue = color["blue"]!
            cell.bgCardView.backgroundColor = UIColor.init(red: CGFloat(red/255), green: CGFloat(green/255), blue: CGFloat(blue/255), alpha: 1)
        } else {
            cell.cardImage.image = UIImage(named: "background.png")
            cell.bgCardView.backgroundColor = .lightGray
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cardDetailVC = storyboard?.instantiateViewController(withIdentifier: "CardDetail") as! CardDetailViewController
        self.navigationController?.pushViewController(cardDetailVC, animated: true)
                        
        let card : CardCafeListData
        card = currentCardArray[indexPath.row]
        cardDetailVC.cardData = card
    }
    
    func deleteCard(cardData: CardCafeListData) { //ลบบัตรสะสมแต้มออกจาก user
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let data = [
            "cafe_id": cardData.cafe_id,
            "cafename_en": cardData.cafename_en,
            "createdate": cardData.createdate,
            "point": cardData.user_point,
            "type": cardData.type
            ] as [String : Any]
        db.collection("user").document(uid).updateData([
            "membercard": FieldValue.arrayRemove([data])
        ]) { err in
            if let err = err {
                print("Error updating document: \(err)")
            } else {
                print("Deleted user's card successfully")
                self.rewardCardTable.reloadData()
            }
        }

    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let data = currentCardArray[indexPath.row]
            deleteCard(cardData: data)
            currentCardArray.remove(at: indexPath.row)
            rewardCardTable.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

extension MyRewardCardViewController {
    
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

