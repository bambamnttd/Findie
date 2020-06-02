//
//  ReviewViewController.swift
//  thesisApp
//
//  Created by Bambam on 22/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

protocol PostReviewDelegate : class {
    func postReview(post: Bool)
}

class ReviewViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var starButton1: UIButton!
    @IBOutlet weak var starButton2: UIButton!
    @IBOutlet weak var starButton3: UIButton!
    @IBOutlet weak var starButton4: UIButton!
    @IBOutlet weak var starButton5: UIButton!
    @IBOutlet weak var reviewText: UITextView!
    
    var delegate: PostReviewDelegate?
    var cafeData : CafeData!
    var rating : Float = 0.0
    let db = Firestore.firestore()
    let getData = GetData()
    let comment_limit : Int = 150
    var vSpinner: UIView?
//    var post = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the shadow color.
        navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        navigationController?.navigationBar.setBackgroundImage(UIColor.clear.as1ptImage(), for: .default)
        setTextView()
        print(cafeData.cafename_en)

        print(Date().timeIntervalSinceReferenceDate)
        print("rating =")
        print(rating)
        checkStarGetOrNot()
    }

    func setTextView() {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 10
        let attributes = [NSAttributedString.Key.paragraphStyle: style]
        reviewText.attributedText = NSAttributedString(string: reviewText.text, attributes: attributes)
        reviewText.font = .systemFont(ofSize: 16)
        reviewText.becomeFirstResponder()
        reviewText.delegate = self
        
        //place holder of text view
        moveCursorToStart(aTextView: reviewText)
        applyPlaceholderStyle(aTextview: reviewText, placeholderText: "เขียนรีวิวถึงร้านนี้...")
    }
    
    //place holder of text view
    func applyPlaceholderStyle(aTextview: UITextView, placeholderText: String) {
        // make it look (initially) like a placeholder
        aTextview.textColor = .lightGray
        aTextview.text = placeholderText
    }
    
    func applyNonPlaceholderStyle(aTextview: UITextView) {
        // make it look like normal text instead of a placeholder
        aTextview.textColor = UIColor.init(red: 59/255, green: 59/255, blue: 59/255, alpha: 1)
        aTextview.alpha = 1.0
    }
    
    func textViewShouldBeginEditing(aTextView: UITextView) -> Bool {
      if aTextView == reviewText && aTextView.text == "เขียนรีวิวถึงร้านนี้..." {
        // move cursor to start
        moveCursorToStart(aTextView: aTextView)
      }
      return true
    }
    
    func moveCursorToStart(aTextView: UITextView) {
        DispatchQueue.main.async {
            aTextView.selectedRange = NSMakeRange(0, 0);
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let newLength = textView.text.utf16.count + text.utf16.count - range.length
        if newLength > 0 { // have text, so don't show the placeholder
          // check if the only text is the placeholder and remove it if needed
          // unless they've hit the delete button with the placeholder displayed
            if textView == reviewText && textView.text == "เขียนรีวิวถึงร้านนี้..." {
                if text.utf16.count == 0 { // they hit the back button
                return false // ignore it
            }
                applyNonPlaceholderStyle(aTextview: reviewText)
                textView.text = ""
            }
            return reviewText.text.count + (text.count - range.length) <= comment_limit
        
        } else {  // no text, so show the placeholder
            applyPlaceholderStyle(aTextview: reviewText, placeholderText: "เขียนรีวิวถึงร้านนี้...")
            moveCursorToStart(aTextView: reviewText)
            return false
        }
    }
    
    @IBAction func post(_ sender: UIBarButtonItem) {
        loading(self.view)
        if reviewText.text == "" || reviewText.text == "เขียนรีวิวถึงร้านนี้..." || reviewText.text.count < 10 || rating == 0.0 {
            let alert = UIAlertController(title: "ผิดพลาด", message: "กรุณาให้คะแนนร้านนี้ และเขียนรีวิวถึงร้านนี้อย่างน้อย 10 ตัวอักษร", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "ปิด", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        }
        else {
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let cafe_id = cafeData.cafe_id
            let cafename_en = cafeData.cafename_en
            let userRef = db.collection("user").document(uid)
            userRef.getDocument { (doc, err) in
                if let doc = doc, doc.exists {
                    let username = doc.get("username") as! String
                    //set data ที่จะเก็บเข้า firestore
                    let data = [
                        "review_id": "",
                        "cafename_en": cafename_en,
                        "cafe_id": cafe_id,
                        "username": username,
                        "uid": uid,
                        "review_text": self.reviewText.text,
                        "time": FieldValue.serverTimestamp(),
                        "timeInterval": Date().timeIntervalSinceReferenceDate,
                        "rating": self.rating
                    ] as [String : Any]

                    //add รีวิว เข้า firestore
                    var ref: DocumentReference? = nil
                    ref = self.db.collection("review").addDocument(data: data) { errr in
                        if let errr = errr {
                            print("Error adding document: \(errr)")
                        }
                        else {
                            print("Document added with ID: \(ref!.documentID)")
                            let reviewRef = self.db.collection("review").document(ref!.documentID)
                            reviewRef.updateData([
                                "review_id" : "\(ref!.documentID)"
                            ]) { er in
                                if let er = er {
                                    print("Error updating document: \(er)")
                                } else {
                                    print("Document successfully updated")
                                    self.removeLoading()
                                    self.getData.calculateRating(cafe_id: cafe_id)
                                    self.delegate?.postReview(post: true)
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                        }
                    }
                } else {
                    print("Document does not exist")
                }
            }
        }
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "เดี๋ยวก่อน!", message: "คุณต้องการออกจากหน้านี้ใช่หรือไม่", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ใช่", style: .default, handler: { action in
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "ไม่", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    
    @IBAction func star1(_ sender: UIButton) {
        rating = 1
        starAction(star: 1, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
    }
    
    @IBAction func star2(_ sender: UIButton) {
        rating = 2
        starAction(star: 2, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
    }
    
    @IBAction func star3(_ sender: UIButton) {
        rating = 3
        starAction(star: 3, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
    }
    
    @IBAction func star4(_ sender: UIButton) {
        rating = 4
        starAction(star: 4, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
    }
    
    @IBAction func star5(_ sender: UIButton) {
        rating = 5
        starAction(star: 5, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
    }
    
    func checkStarGetOrNot() {
        if rating != 0 {
            starAction(star: rating, starButton1: starButton1, starButton2: starButton2, starButton3: starButton3, starButton4: starButton4, starButton5: starButton5)
        }
    }
    
    func starAction(star: Float, starButton1: UIButton, starButton2: UIButton, starButton3: UIButton, starButton4: UIButton, starButton5: UIButton) {
        switch star {
        case 1 :
            starButton1.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton2.setImage(UIImage(named: "star_gray.png"), for: .normal)
            starButton3.setImage(UIImage(named: "star_gray.png"), for: .normal)
            starButton4.setImage(UIImage(named: "star_gray.png"), for: .normal)
            starButton5.setImage(UIImage(named: "star_gray.png"), for: .normal)
        case 2 :
            starButton1.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton2.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton3.setImage(UIImage(named: "star_gray.png"), for: .normal)
            starButton4.setImage(UIImage(named: "star_gray.png"), for: .normal)
            starButton5.setImage(UIImage(named: "star_gray.png"), for: .normal)
        case 3 :
            starButton1.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton2.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton3.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton4.setImage(UIImage(named: "star_gray.png"), for: .normal)
            starButton5.setImage(UIImage(named: "star_gray.png"), for: .normal)
        case 4 :
            starButton1.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton2.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton3.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton4.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton5.setImage(UIImage(named: "star_gray.png"), for: .normal)
        default:
            starButton1.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton2.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton3.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton4.setImage(UIImage(named: "star_yellow.png"), for: .normal)
            starButton5.setImage(UIImage(named: "star_yellow.png"), for: .normal)
        }
    }
}

extension ReviewViewController {
    
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
