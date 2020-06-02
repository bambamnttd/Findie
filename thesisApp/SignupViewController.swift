//
//  SignupViewController.swift
//  thesisApp
//
//  Created by Bambam on 4/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Foundation
import Firebase

class SignupViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var warningLabel: UILabel!
    
    var activityView:UIActivityIndicatorView!
    
    @IBAction func close(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
        profileImageView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(imageTap)
        profileImageView.layer.cornerRadius = profileImageView.bounds.height / 2
        profileImageView.clipsToBounds = true
        profileImageView.image = UIImage(named: "profile.png")
        
        emailTextField.setBottomBorder()
        passwordTextField.setBottomBorder()
        nameTextField.setBottomBorder()
        signupButton.layer.cornerRadius = 5
        
        //เช็ค password ว่าครบ 6 ไหม
        passwordTextField.addTarget(self, action: #selector(checkText(textfield:)), for: .editingChanged)
        
        self.hideKeyboard()
    }
    
    @objc func checkText(textfield: UITextField) {
        if (passwordTextField.text?.count ?? 0 < 6) {
            warningLabel.text = "รหัสผ่านอย่างน้อย 6 ตัวอักษร*"
            warningLabel.textColor = .red
        }
        else{
            warningLabel.text = "รหัสผ่านใช้งานได้"
            warningLabel.textColor = UIColor(red: 120/255, green: 183/255, blue: 60/255, alpha: 1)
        }
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        if let email = Auth.auth().currentUser {
//            self.performSegue(withIdentifier: "toHomeScreen", sender: self)
//        }
//    }
    
    func addData() {
        let name = nameTextField.text!
        let email = emailTextField.text!
        let password = passwordTextField.text!
        let uid = Auth.auth().currentUser?.uid as! String
            
        //ถ้าเลือกรูปใส่เข้าไป
        if self.profileImageView.image != UIImage(named: "profile.png") {
            ///upload user image to storage and get url
            guard let image = self.profileImageView.image,
                let data = image.jpegData(compressionQuality: 1.0) else {
                    print("error")
                    return
            }
            let imageName = UUID().uuidString
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            let imageReference = Storage.storage().reference().child("user").child("\(imageName).jpeg")
            
            //upload image to storage
            imageReference.putData(data, metadata: metadata) { (metadata, err) in
                if let err = err {
                    print("error")
                    return
                }
                else {
                    print("อัพรูป")
                }
                
                //get URL of image from storage
                imageReference.downloadURL(completion: { (url, err) in
                    if let err = err {
                        print("error")
                        return
                    }
                    guard let url = url else {
                        print("error")
                        return
                    }
                    
                    let user_imageURL = url.absoluteString
                    let userData = [
                        "username": name,
                        "email": email,
                        "password": password,
                        "uid": uid,
                        "user_imageURL": user_imageURL,
                        "phone_number": "",
                        "membercard": []
                    ] as [String : Any]
                        
                    ///add user data to firestore
                    self.db.collection("user").document(uid).setData(userData) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written! \(uid)")
                        }
                    }
                })
            }
        } else { //ถ้าไม่ได้เลือกรูปใส่เข้าไป
            let userData = [
                "username": name,
                "email": email,
                "password": password,
                "uid": uid,
                "user_imageURL": "",
                "phone_number": "",
                "membercard": []
            ] as [String : Any]
                
            ///add user data to firestore
            self.db.collection("user").document(uid).setData(userData) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written! \(uid)")
                }
            }
        }
    }
    
    @IBAction func signUp(_ sender: Any) {
        guard let name = nameTextField.text else { return }
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }

        Auth.auth().createUser(withEmail: email, password: password) { name, error in
            if error == nil && name != nil {
                print("สมัครสมาชิกเรียบร้อยแล้ว!")
                self.addData()
                
                let changRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changRequest?.displayName = email
                changRequest?.commitChanges { error in
                    if error == nil {
                        print("User display name changed!")
                        let alert = UIAlertController(title: "สมัครสมาชิกเรียบร้อยแล้ว", message: nil, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "ตกลง", style: .default, handler: { action in
                            self.dismiss(animated: true, completion: nil)
                        }))
                        self.present(alert, animated: true)
//                        self.dismiss(animated: false, completion: nil)
                        
                    }

                }
                
            } else {
                print("สมัครสมาชิกไม่สำเร็จ: \(error! .localizedDescription)")
                let alert = UIAlertController(title: "สมัครสมาชิกไม่สำเร็จ", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ตกลง", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        }
//        showData()
        
    }
    
    @objc func openImagePicker(_ sender:Any) {
        showImagePickerController()
    }
    
    func showImagePickerController() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.allowsEditing = true
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            profileImageView.image = editedImage
            
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            profileImageView.image = originalImage
        }
        dismiss(animated: true, completion: nil)
            
    }

}
