//
//  RewardListCell.swift
//  thesisApp
//
//  Created by Bambam on 16/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

protocol NotLoginDelegate : class {
    func goLogin()
}

class RewardListCell: UITableViewCell {
    
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var addCardButton: UIButton!
    
    var link: RewardListViewController?
    let db = Firestore.firestore()
    var data: RewardCafeListData!
    var delegate: NotLoginDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        logoImage.layer.cornerRadius = logoImage.bounds.height / 2
        addCardButton.layer.borderWidth = 1
        addCardButton.layer.borderColor = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).cgColor
        addCardButton.layer.cornerRadius = 10
        addCardButton.addTarget(self, action: #selector(addCafeCard), for: .touchUpInside)
        addCardButton.setTitle("เพิ่ม", for: .normal)
//        addCardButton.titleLabel?.font = UIFont(name: "Kanit", size: 14)
        addCardButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -80, bottom: 0, right: 0)
        addCardButton.setImage(UIImage(named: "plus.png"), for: .normal)
        addCardButton.imageView?.contentMode = .scaleAspectFit
        addCardButton.imageEdgeInsets = UIEdgeInsets(top: 9, left: -30, bottom: 9, right: 0)
    }
    
    @objc private func addCafeCard() {
        print("เพิ่มบัตร")
        if Auth.auth().currentUser != nil {
            link?.someMethodIwantToCall(cell:self)
            addCardButton.isHidden = true
            
            //update data แบบ map
            let cafeid = data.cafe_id
            let cafename_en = data.cafename_en
            let type = data.type
            let createdate = Date()
            guard let uid = Auth.auth().currentUser?.uid else { return }
            
            let userRef = db.collection("user").document(uid)
            
            userRef.updateData([
                "membercard": FieldValue.arrayUnion([
                    ["cafe_id": cafeid,
                    "cafename_en": cafename_en,
                    "type": type,
                    "point": 0,
                    "createdate": createdate]
                ])
            ]) { err in
                if let err = err {
                    print("Error updating document: \(err)")
                } else {
                    print("Document successfully updated")
                }
            }
        } else {
            delegate?.goLogin()
        }
    }
    
    ///เช็คว่าถ้ามีการ์ดแล้วก็จะไม่ขึ้นให้กดเพิ่มการ์ดอีก
    func checkAddCard() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("user").document(uid)
        let cafeid = data.cafe_id
        userRef.getDocument { (document, err) in
            if let document = document, document.exists {
                let membercards = document.get("membercard") as! [[String:Any]]
                for membercard in membercards {
                    if membercard["cafe_id"] as! String == cafeid {
                        self.addCardButton.isHidden = true
                    }
                }
            } else {
                print("Document does not exist")
            }
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
