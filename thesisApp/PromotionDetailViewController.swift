//
//  PromotionDetailViewController.swift
//  thesisApp
//
//  Created by Bambam on 15/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class PromotionDetailViewController: UIViewController {
    
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var cafenameLabel: UILabel!
    @IBOutlet weak var expiredDateLabel: UILabel!
    @IBOutlet weak var promotionImage: UIImageView!
    @IBOutlet weak var conditionTextView: UITextView!
    
    let db = Firestore.firestore()
    var promotionData: PromotionData!
    let callFunc = GetData()
    var strings = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBarItems()
        navigationItem.title = "โปรโมชั่น"
        let topic = promotionData.promotion_topic
        let cafename_en = promotionData.cafename_en
        let imageURL = promotionData.promotion_imageURL
        topicLabel.text = topic
        cafenameLabel.text = cafename_en
        callFunc.getImage(imageURL: imageURL, imageView: promotionImage)
        
        let timeFormat = DateFormatter()
        timeFormat.dateFormat = "dd MMM yy"
        if promotionData.startdate == promotionData.enddate {
            let expdate = timeFormat.string(from: promotionData.enddate)
            expiredDateLabel.text = " \(expdate) นี้เท่านั้น"
        } else {
            let startdate = timeFormat.string(from: promotionData.startdate)
            let enddate = timeFormat.string(from: promotionData.enddate)
            expiredDateLabel.text = "ตั้งแต่ \(startdate) - \(enddate)"
        }
        conditionTextView.text = promotionData.promotion_detail
//        setDetailLabel()
    }
    
    func setDetailLabel() {
        let promotion_id = promotionData.promotion_id
        let promotionRef = db.collection("promotion").document(promotion_id)
        promotionRef.getDocument { (document, err) in
            if let document = document, document.exists {
                let promotion_detail = document.get("promotion_detail") as! [String]
                let promotion_date = document.get("promotion_date") as! String
                self.strings = promotion_detail
                if promotion_date.contains(" - ") || promotion_date.contains("เป็นต้นไป") {
                    self.strings.append("โปรโมชั่นนี้ใช้ได้ตั้งแต่ \(promotion_date)")
                }
                else {
                    self.strings.append("โปรโมชั่นนี้เฉพาะ \(promotion_date) นี้เท่านั้น")
                }
                
                var attributes = [NSAttributedString.Key: Any]()
                attributes[.font] = UIFont(name: "Helvetica Neue", size: 14)
                attributes[.foregroundColor] = UIColor.init(red: 49/255, green: 49/255, blue: 51/255, alpha: 1)
                
                let paragraphStyle = NSMutableParagraphStyle()
                attributes[.paragraphStyle] = paragraphStyle
                paragraphStyle.paragraphSpacing = 2
                paragraphStyle.lineSpacing = 2
                
                let string = self.strings.joined(separator: "\n")
                self.conditionTextView.attributedText = NSAttributedString(string: string, attributes: attributes)
            }
            else {
                print("Document does not exist")
            }
        }
    }
}
