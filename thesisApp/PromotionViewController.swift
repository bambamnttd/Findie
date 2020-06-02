//
//  PromotionViewController.swift
//  thesisApp
//
//  Created by Bambam on 15/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

struct PromotionData {
    var promotion_id: String
    var cafe_id: String
    var cafename_en: String
    var promotion_topic: String
    var promotion_detail: String
    var startdate: Date
    var enddate: Date
    var promotion_imageURL: String
}

class PromotionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var promotionTable: UITableView!
    
    let db = Firestore.firestore()
    var promotionArray = [PromotionData]()
    let callFunc = GetData()
    var vSpinner: UIView?
    
    func getPromotion() {
        loading(self.view)
        let promotionRef = self.db.collection("promotion").order(by: "createdate", descending: true)
        promotionRef.getDocuments { (snapshot, error) in
            if error == nil && snapshot != nil {
                for document in snapshot!.documents {
                    let promotion_id = document.get("promotion_id") as! String
                    let cafe_id = document.get("cafe_id") as! String
                    let promotion_topic = document.get("promotion_topic") as! String
                    let promotion_detail = document.get("promotion_detail") as! String
                    let startdate = document.get("startdate") as! Timestamp
                    let enddate = document.get("enddate") as! Timestamp
                    let promotion_imageURL = document.get("promotion_imageURL") as! String
                    self.promotionArray.append(PromotionData(promotion_id: promotion_id, cafe_id: cafe_id, cafename_en: "", promotion_topic: promotion_topic, promotion_detail: promotion_detail, startdate: startdate.dateValue(), enddate: enddate.dateValue(), promotion_imageURL: promotion_imageURL))
                }
                let dispatch = DispatchGroup()
                self.getCafename(allId: self.promotionArray, dispatch: dispatch){ (arr) in
                    dispatch.notify(queue: .main, execute: {
                        self.promotionArray.removeAll()
                        self.promotionArray = arr
                        self.removeLoading()
                        self.promotionTable.reloadData()
                    })
                }
            }
        }
    }
    
    func getCafename(allId: [PromotionData], dispatch:DispatchGroup, completed: @escaping ([PromotionData]) -> Void) {
        let arrayLength = allId.count
        var array = allId
        for n in 0..<arrayLength {
            let id = array[n].cafe_id
            let cafeRef = self.db.collection("cafe").document(id)
            dispatch.enter()
            cafeRef.getDocument { (doc, err) in
                if let doc = doc, doc.exists {
                    let cafename = doc.get("cafename_en") as! String
                    array[n].cafename_en = cafename
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getPromotion()
        promotionTable.dataSource = self
        promotionTable.delegate = self
        
        setupNavigationBarItems()
        
        navigationItem.title = "โปรโมชั่น"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.barTintColor = .white
    }

    override func viewWillDisappear(_ animated: Bool){
        navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        navigationController?.navigationBar.setBackgroundImage(UIColor.clear.as1ptImage(), for: .default)
        self.navigationController?.navigationBar.barTintColor = .white
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return promotionArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PromotionCell", for: indexPath) as? PromotionCell else {
            return UITableViewCell()
        }
        let promotion = promotionArray[indexPath.row]
        cell.cafenameLabel.text = promotion.cafename_en
        cell.topicLabel.text = promotion.promotion_topic
        callFunc.getImage(imageURL: promotion.promotion_imageURL, imageView: cell.promotionImage)
        let timeFormat = DateFormatter()
        timeFormat.dateFormat = "dd MMM yy"
        let expdate = timeFormat.string(from: promotion.enddate)
        cell.expiredDateLabel.text = "ใช้ได้ถึง: \(expdate)"
        let bgColorView = UIView()
        bgColorView.backgroundColor = .white
        cell.selectedBackgroundView = bgColorView
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let promotionDetailVC = storyboard?.instantiateViewController(withIdentifier: "PromotionDetailVC") as! PromotionDetailViewController
        self.navigationController?.pushViewController(promotionDetailVC, animated: true)
        let promotion: PromotionData
        promotion = promotionArray[indexPath.row]
        promotionDetailVC.promotionData = promotion
    }
}

extension PromotionViewController {
    
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



