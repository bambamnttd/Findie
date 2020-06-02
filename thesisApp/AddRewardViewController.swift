//
//  AddRewardViewController.swift
//  thesisApp
//
//  Created by Bambam on 26/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI
import AVFoundation

protocol AddPointDelegate : class {
    func addPoint(add: Bool)
}

class AddRewardViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var pointTextField: UITextField!
    @IBOutlet weak var warningLabel: UILabel!
    
    var delegate: AddPointDelegate?
    var qrData: QRData!
    var cardData: CardCafeListData!
    let db = Firestore.firestore()
    let getData = GetData()
    var vSpinner: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(qrData?.codeString)
        sendButton.layer.cornerRadius = 5
        logoImage.layer.cornerRadius = logoImage.bounds.height / 2
        logoImage.clipsToBounds = true
        getData.getImage(imageURL: cardData.logoURL, imageView: logoImage)
        
        pointTextField.setBottomBorder()
        pointTextField.delegate = self
        pointTextField.keyboardType = .numberPad
        self.hideKeyboard()
        warningLabel.isHidden = true
    }
    
    @IBAction func check(_ sender: UIButton) {
        let cafe_id = cardData.cafe_id
        let cafename_en = cardData.cafename_en
        let type = cardData.type
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let text = pointTextField.text else { return }
        if text != "" {
            loading(self.view)
            if let point = Int(text) {
                warningLabel.isHidden = true
                
                //update user's point to firestore
                let userRef = db.collection("user").document(uid)
                userRef.getDocument { (document, err) in
                    if let document = document, document.exists {
                        let membercards = document.get("membercard") as! [[String:Any]]
                        for membercard in membercards {
                            if membercard["cafe_id"] as! String == cafe_id {
                                let oldpoint = membercard["point"] as! Int
                                let createdate = membercard["createdate"] as! Timestamp
                                var newpoint: Int!
                                newpoint = oldpoint + point
                                print("คะแนนที่ได้ \(point)")
                                print("คะแนนเดิมที่มี \(oldpoint)")
                                print("รวม \(String(newpoint))")
                                userRef.updateData([
                                    "membercard": FieldValue.arrayRemove([
                                        ["cafe_id": cafe_id,
                                        "cafename_en": cafename_en,
                                        "type": type,
                                        "point": oldpoint,
                                        "createdate": createdate]
                                    ])
                                ]) { err in
                                    if let err = err {
                                        print("Error updating document: \(err)")
                                    } else {
                                        print("Document successfully updated")
                                    }
                                }
                                
                                userRef.updateData([
                                    "membercard": FieldValue.arrayUnion([
                                        ["cafe_id": cafe_id,
                                        "cafename_en": cafename_en,
                                        "type": type,
                                        "point": newpoint,
                                        "createdate": createdate]
                                    ])
                                ]) { err in
                                    if let err = err {
                                        print("Error updating document: \(err)")
                                    } else {
                                        print("Document successfully updated")
                                    }
                                }
                                self.removeLoading()
                                self.delegate?.addPoint(add: true)
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    } else {
                        print("Document does not exist")
                    }
                }
                
            } else {
                warningLabel.text = "กรุณาใส่เป็นตัวเลขเท่านั้น*"
                warningLabel.isHidden = false
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        } else {
            warningLabel.text = "กรุณาใส่แต้มที่ลูกค้าได้*"
            warningLabel.isHidden = false
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
    
    ///limit textfield ให้พิมพ์ได้แค่ 3 ตัว
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
      let maxLength = 2
      let currentString: NSString = pointTextField.text! as NSString
      let newString: NSString =
        currentString.replacingCharacters(in: range, with: string) as NSString
      return newString.length <= maxLength
    }
    
}

extension AddRewardViewController {
    
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


