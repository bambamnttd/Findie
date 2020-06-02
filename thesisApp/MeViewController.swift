//
//  MeViewController.swift
//  thesisApp
//
//  Created by Bambam on 14/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import FirebaseUI

class MeViewController: UIViewController {

    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var bgUserImage: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var menuCollection: UICollectionView!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var loginView: UIView!
    @IBOutlet weak var loginButton: UIButton!
    
    let db = Firestore.firestore()
    let getData = GetData()
    var topicArray = [String]()
    var iconArray = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        navigationController?.navigationBar.setBackgroundImage(UIColor.clear.as1ptImage(), for: .default)
        setImageView()
        
        menuCollection.delegate = self
        menuCollection.dataSource = self
        topicArray = ["รีวิวของฉัน", "บัตรสะสมแต้ม", "ที่บันทึกไว้", "การตั้งค่า", "ออกจากระบบ"]
        iconArray = ["review.png", "rewardcard.png", "bookmark.png", "setting.png", "logout.png"]
        
        let profileTap = UITapGestureRecognizer(target: self, action: #selector(openShowProfile))
        profileView.isUserInteractionEnabled = true
        profileView.addGestureRecognizer(profileTap)
        
        loginButton.layer.cornerRadius = 5
        if Auth.auth().currentUser != nil {
            loginView.isHidden = true
            getUserData()
        } else {
            navigationItem.title = "ฉัน"
            loginView.isHidden = false
            loginButton.addTarget(self, action: #selector(openVC), for: .touchUpInside)
        }
    }
    
    @objc func openVC() {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "VC") as! ViewController
        vc.from = "MeVC"
        self.present(vc, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //ซ่อน nav bar อันนี้มันจะซ่อนทุกหน้าเลย เราเลยต้องใช้ตรง viewWillDisappear เพื่อเรียกมันกลับมา
        if Auth.auth().currentUser != nil {
            navigationController?.setNavigationBarHidden(true, animated: false)
        } else {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }

    override func viewWillDisappear(_ animated: Bool){
        //เอา nav bar กลับมา
        if Auth.auth().currentUser != nil {
            navigationController?.setNavigationBarHidden(false, animated: true)
        } else {
            navigationController?.setNavigationBarHidden(false, animated: false)
        }
    }
    
    func setImageView() {
        userImage.layer.cornerRadius = userImage.bounds.height / 2
        userImage.clipsToBounds = true
//        userImage.layer.borderColor = UIColor.white.cgColor
//        userImage.layer.masksToBounds = true
//        userImage.layer.borderWidth = 5
        
        //background image
        let darkView = UIView()
        darkView.backgroundColor = .black
        darkView.alpha = 0.4
        darkView.frame = bgUserImage.bounds
        let lightBlur = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: lightBlur)
        blurView.frame = bgUserImage.bounds
        bgUserImage.addSubview(blurView)
        bgUserImage.addSubview(darkView)
    }
    
    func getUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let user = db.collection("user").document(uid)
        user.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                return
            }
            let username = document.get("username") as! String
            let imageURL = document.get("user_imageURL") as! String
            self.usernameLabel.text = username
            if imageURL != "" {
                self.getData.getImage(imageURL: imageURL, imageView: self.userImage)
                self.getData.getImage(imageURL: imageURL, imageView: self.bgUserImage)
            } else {
                self.userImage.image = UIImage(named: "background.png")
                self.bgUserImage.image = UIImage(named: "background.png")
            }
            print("meVC updated")
        }
    }
    
    @objc func openShowProfile() {
        let showProfileVC = storyboard?.instantiateViewController(withIdentifier: "ShowProfileVC") as! ShowProfileViewController
        self.navigationController?.pushViewController(showProfileVC, animated: true)
    }

}

extension MeViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topicArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width, height: 60)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = menuCollection.dequeueReusableCell(withReuseIdentifier: "MenuCell", for: indexPath) as? MenuCell else {
            return UICollectionViewCell()
        }
        cell.topicLabel.text = topicArray[indexPath.item]
        cell.iconImage.image = UIImage(named: iconArray[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 {
            let showReviewVC = storyboard?.instantiateViewController(withIdentifier: "ShowReviewVC") as! ShowReviewViewController
            showReviewVC.hidesBottomBarWhenPushed = true
            showReviewVC.from = "MeVC"
            self.navigationController?.pushViewController(showReviewVC, animated: true)
        }
        else if indexPath.item == 1 {
            let myRewardCardVC = storyboard?.instantiateViewController(withIdentifier: "MyRewardCardVC") as! MyRewardCardViewController
            self.navigationController?.pushViewController(myRewardCardVC, animated: true)
        }
        else if indexPath.item == 2 {
            let favoriteVC = storyboard?.instantiateViewController(withIdentifier: "FavoriteVC") as! FavoriteViewController
            favoriteVC.hidesBottomBarWhenPushed = true
            favoriteVC.from = "me"
            self.navigationController?.pushViewController(favoriteVC, animated: true)
        }
        else if indexPath.item == 3 {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                })
            }
        }
        else if indexPath.item == 4 {
            try! Auth.auth().signOut()
            self.dismiss(animated: false, completion: nil)
        }
    }
    
}
