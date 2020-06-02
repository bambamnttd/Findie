//
//  RewardListViewController.swift
//  thesisApp
//
//  Created by Bambam on 15/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

extension RewardListViewController: NotLoginDelegate {
    func goLogin() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
        vc.from = "RewardListVC"
        self.present(vc, animated: true, completion: nil)
    }
}

class RewardListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var menuCollection: UICollectionView!
    @IBOutlet weak var table: UITableView!
    @IBOutlet var table2: UITableView!
    
    let db = Firestore.firestore()
    var cafeArray = [RewardCafeListData]()
    var currentCafeArray = [RewardCafeListData]()
    var cardArray = [CardCafeListData]()
    var currentCardArray = [CardCafeListData]()
    var selectedArray = [String]()
    var selectedIndex = 0
    var selectedIndexPath = IndexPath(item: 0, section: 0)
    var menuTitles = ["ร้านที่ร่วมรายการ","บัตรของฉัน"]
    var indicatorView = UIView()
    var indicatorHeight : CGFloat = 3
    var addCardArray = [String]()
    let getData = GetData()
    var imageURLArray = [String]()
    let redColor: UIColor! = .init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1)
    let editButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 20))
    var clickEdit = 0
    var vSpinner: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.table.dataSource = self
        self.table.delegate = self

        self.table2.dataSource = self
        self.table2.delegate = self
        
        table.isHidden = false
        table2.isHidden = true
        
        setupNavigationBarItems()
//        setupEditButtonToNavBarItem()
        editButton.isHidden = true
        self.navigationItem.title = "สะสมแต้ม"
        
        menuCollection.selectItem(at: selectedIndexPath, animated: false, scrollPosition: .centeredVertically)
        indicatorView.backgroundColor = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1)
        indicatorView.frame = CGRect(x: menuCollection.bounds.minX, y: menuCollection.bounds.maxY - indicatorHeight, width: menuCollection.bounds.width / CGFloat(menuTitles.count), height: indicatorHeight)
        menuCollection.addSubview(indicatorView)
        
        getCafeData()
        getMemberCard()
        
    }

    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        //tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool){
        //tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIColor.clear.as1ptImage(), for: .default)
    }
        
    func someMethodIwantToCall(cell: UITableViewCell) {
        print("ใน view controller")
        let indexPathTapped = table.indexPath(for: cell)
        let name = cafeArray[indexPathTapped!.row].cafename_en
        self.addCardArray.append(name)
        print(addCardArray)
    }
    
    func getCafeData() {
        loading(self.view)
        db.collection("cafe").getDocuments { (snapshot, error) in
            if error == nil && snapshot != nil {
                for document in snapshot!.documents {
                    let cafeid = document.get("cafe_id") as! String
                    if document.get("membercard") != nil && cafeid != "" {
                        let memberCard = document.get("membercard") as! Bool
                        if memberCard == true && document.get("type") != nil {
                            let cafename_en = document.get("cafename_en") as! String
                            let type = document.get("type") as! String
                            
                            let data = self.db.collection("cafe_image").document(cafeid)
                            data.getDocument { (document, error) in
                                if let document = document, document.exists {
                                    if document.get("cafe_logo") != nil && document.get("cafe_cover") != nil {
                                        let logoURL = document.get("cafe_logo") as! String
                                        let coverURL = document.get("cafe_cover") as! String
                                        if logoURL != "" && coverURL != "" {
                                            self.cafeArray.append(RewardCafeListData(cafe_id: cafeid, cafename_en: cafename_en, type: type, reward: "", logoURL: logoURL))
                                            self.currentCafeArray = self.cafeArray.sorted { $0.cafename_en < $1.cafename_en }
                                        }
                                    }
                                } else {
                                    print("Document does not exist")
                                }
                                self.removeLoading()
                                self.table.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
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
                            self.table2.reloadData()
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
                    let color = document.get("cafe_color") as! [String: Float]
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
    
    func setupEditButtonToNavBarItem() {
        editButton.contentHorizontalAlignment = .right
        editButton.setTitle("แก้ไข", for: .normal)
        editButton.setTitleColor(redColor, for: .normal)
        editButton.addTarget(self, action: #selector(clickEditButton), for: .touchUpInside)
            
        let menuBarItem = UIBarButtonItem(customView: editButton)
        navigationItem.rightBarButtonItem = menuBarItem
    }
    
    @objc func clickEditButton() {
        if clickEdit == 0 {
            editButton.setTitle("เสร็จสิ้น", for: .normal)
            clickEdit = 1
        }
        else {
            editButton.setTitle("แก้ไข", for: .normal)
            clickEdit = 0
        }
    }
    
    func refreshList() {
        if selectedIndex == 0 {
            table.isHidden = false
            table2.isHidden = true
            editButton.isHidden = true
        } else {
            table2.isHidden = false
            table.isHidden = true
            editButton.isHidden = false
        }
        let desiredX = (menuCollection.bounds.width / CGFloat(menuTitles.count)) * CGFloat(selectedIndex)
        indicatorView.frame = CGRect(x: desiredX, y: menuCollection.bounds.maxY - indicatorHeight, width: menuCollection.bounds.width / CGFloat(menuTitles.count), height: indicatorHeight)
    }
    
    //table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (tableView == table) {
            return currentCafeArray.count
        }
        else {
            return currentCardArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (tableView == table) {
            return 102
        }
        else {
            return 240
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (tableView == table) {
            guard let cell = table.dequeueReusableCell(withIdentifier: "rewardcell", for: indexPath) as? RewardListCell else {
                return UITableViewCell()
            }
            let cafe = currentCafeArray[indexPath.row]
            cell.nameLabel.text = cafe.cafename_en
            cell.typeLabel.text = cafe.type
            cell.link = self
            cell.data = cafe
            cell.delegate = self
            cell.addCardButton.isHidden = false
            
            ///เช็คว่าถ้ามีการ์ดแล้วก็จะไม่ขึ้นให้กดเพิ่มการ์ดอีก
            if Auth.auth().currentUser != nil {
                let uid = Auth.auth().currentUser?.uid
                let userRef = db.collection("user").document(uid!)
                let cafeid = cafe.cafe_id
                userRef.getDocument { (document, err) in
                    if let document = document, document.exists {
                        let membercards = document.get("membercard") as! [[String:Any]]
                        for membercard in membercards {
                            if membercard["cafe_id"] as! String == cafeid {
                                cell.addCardButton.isHidden = true
                            }
                        }
                    } else {
                        print("Document does not exist")
                    }
                }
            }

            //ใช้ firebaseUI เลยดึงรูปออกมาได้ไวกว่าง่ายกว่า
            getData.getImage(imageURL: cafe.logoURL, imageView: cell.logoImage)
            return cell
        }
        else {
            guard let cell = table2.dequeueReusableCell(withIdentifier: "cardcell", for: indexPath) as? CardListCell else {
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
        
            //รูป logo
            
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
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView == table2) {
            if clickEdit == 0 {
                let cardDetailVC = storyboard?.instantiateViewController(withIdentifier: "CardDetail") as! CardDetailViewController
                self.navigationController?.pushViewController(cardDetailVC, animated: true)
                
                let card : CardCafeListData
                card = currentCardArray[indexPath.row]
                cardDetailVC.cardData = card
                cardDetailVC.cardColor = card.color
            }
        }
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
                self.table.reloadData()
            }
        }

    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if (tableView == table2) {
            if editingStyle == .delete {
                let data = currentCardArray[indexPath.row]
                deleteCard(cardData: data)
                currentCardArray.remove(at: indexPath.row)
                table2.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }
}

extension RewardListViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuTitles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RewardMenuCell", for: indexPath) as! RewardMenuCell
        cell.setupCell(text: menuTitles[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width / CGFloat(menuTitles.count), height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
        refreshList()
    }

}

extension RewardListViewController {
    
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

