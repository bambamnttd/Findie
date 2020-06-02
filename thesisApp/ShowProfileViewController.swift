//
//  ShowProfileViewController.swift
//  thesisApp
//
//  Created by Bambam on 24/4/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
}

class ShowProfileViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var userImage : UIImageView!
    @IBOutlet weak var coverImage : UIImageView!
    @IBOutlet weak var cameraImage : UIImageView!
    @IBOutlet weak var usernameLabel : UILabel!
    @IBOutlet weak var usernameTextField : UITextField!
    @IBOutlet weak var emailTextField : UITextField!
    @IBOutlet weak var phoneTextField : UITextField!
    @IBOutlet weak var logoutButton : UIButton!
    
    let db = Firestore.firestore()
    let getData = GetData()
    let grayColor = UIColor.init(red: 138/255, green: 138/255, blue: 142/255, alpha: 1)
    var status = ""
    var vSpinner: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupUI()
        getUserData()
        phoneTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    }

    override func viewWillDisappear(_ animated: Bool){
        self.navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIColor.clear.as1ptImage(), for: .default)
    }
    
    func setupNavBar() {
        let editButton = UIButton()
        if status == "edit" {
            editButton.setTitle("บันทึก", for: .normal)
            editButton.addTarget(self, action: #selector(updateData), for: .touchUpInside)
        }
        else {
            editButton.setTitle("แก้ไข", for: .normal)
            editButton.setTitleColor(.white, for: .normal)
            editButton.addTarget(self, action: #selector(editData), for: .touchUpInside)
        }
        
        
        let menuBarItem1 = UIBarButtonItem(customView: editButton)
        
        let backButton = UIButton()
        backButton.setImage(UIImage(named: "back_circle.png"), for: .normal)
        backButton.addTarget(self, action: #selector(backToPrevious), for: .touchUpInside)
        backButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let menuBarItem2 = UIBarButtonItem(customView: backButton)
        let currWidth = menuBarItem2.customView?.widthAnchor.constraint(equalToConstant:  32)
        let currHeight = menuBarItem2.customView?.heightAnchor.constraint(equalToConstant: 32)
        currWidth?.isActive = true
        currHeight?.isActive = true
        
        navigationItem.rightBarButtonItem = menuBarItem1
        navigationItem.leftBarButtonItem = menuBarItem2
        navigationController?.navigationBar.isTranslucent = true
    }
    
    @objc func editData() {
        let showProfileVC = storyboard?.instantiateViewController(withIdentifier: "ShowProfileVC") as! ShowProfileViewController
        self.navigationController?.pushViewController(showProfileVC, animated: true)
        showProfileVC.status = "edit"
    }
    
    @objc func updateData() {
        loading(self.view)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let username = usernameTextField.text!
        let phonenumber = phoneTextField.text!
        
        let userRef = db.collection("user").document(uid)
        
        if self.userImage.image != UIImage(named: "profile.png") {
        ///upload user image to storage and get url
            guard let image = self.userImage.image,
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
                    userRef.updateData([
                        "username": username,
                        "phone_number": phonenumber,
                        "user_imageURL": user_imageURL
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                            self.removeLoading()
                            self.performSegueToReturnBack()
                        }
                    }
                })
            }
        }
    }
    
    @objc func logout() {
        try! Auth.auth().signOut()
        self.dismiss(animated: false, completion: nil)
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
            let email = document.get("email") as! String
            let password = document.get("password") as! String
            let imageURL = document.get("user_imageURL") as! String
            let phonenumber = document.get("phone_number") as! String
            self.usernameLabel.text = username
            self.usernameTextField.text = username
            self.emailTextField.text = email
            self.phoneTextField.text = phonenumber
            self.getData.getImage(imageURL: imageURL, imageView: self.userImage)
            self.getData.getImage(imageURL: imageURL, imageView: self.coverImage)
            print("showVC updated")
        }
    }
    
    func setupUI() {
        logoutButton.layer.borderColor = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).cgColor
        logoutButton.addTarget(self, action: #selector(logout), for: .touchUpInside)
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.cornerRadius = 5
        userImage.layer.cornerRadius = userImage.bounds.height / 2
        userImage.clipsToBounds = true
        
        //background image
        let darkView = UIView()
        darkView.backgroundColor = .black
        darkView.alpha = 0.4
        darkView.frame = coverImage.bounds
        let lightBlur = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: lightBlur)
        blurView.frame = coverImage.bounds
        coverImage.addSubview(blurView)
        coverImage.addSubview(darkView)
        
        if status == "edit" {
            let imageTap1 = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
            let imageTap2 = UITapGestureRecognizer(target: self, action: #selector(openImagePicker))
            userImage.isUserInteractionEnabled = true
            userImage.addGestureRecognizer(imageTap1)
            cameraImage.isUserInteractionEnabled = true
            cameraImage.addGestureRecognizer(imageTap2)
            
            usernameTextField.setBottomBorder()
            usernameTextField.isEnabled = true
            
            emailTextField.setBottomBorder()
            emailTextField.isEnabled = false
            emailTextField.textColor = grayColor
            
            phoneTextField.setBottomBorder()
            phoneTextField.keyboardType = .numberPad
            phoneTextField.isEnabled = true
        
            cameraImage.isHidden = false
            logoutButton.isHidden = true
            usernameLabel.isHidden = true
            
            self.hideKeyboard()
            
        }
        else {
            usernameTextField.isEnabled = false
            emailTextField.isEnabled = false
            phoneTextField.isEnabled = false
            cameraImage.isHidden = true
            logoutButton.isHidden = false
            usernameLabel.isHidden = false
            usernameTextField.addImage(image: UIImage(named: "user.png")!)
            emailTextField.addImage(image: UIImage(named: "email.png")!)
            phoneTextField.addImage(image: UIImage(named: "phone.png")!)
        }
    }
    
    func formattedNumber(number: String) -> String {
        let cleanPhoneNumber = number.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let mask = "XXX-XXX-XXXX"

        var result = ""
        var index = cleanPhoneNumber.startIndex
        for ch in mask where index < cleanPhoneNumber.endIndex {
            if ch == "X" {
                result.append(cleanPhoneNumber[index])
                index = cleanPhoneNumber.index(after: index)
            } else {
                result.append(ch)
            }
        }
        return result
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = phoneTextField.text else { return false }
        let newString = (text as NSString).replacingCharacters(in: range, with: string)
        phoneTextField.text = formattedNumber(number: newString)
        return false
    }
}

extension ShowProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
            userImage.image = editedImage
            coverImage.image = editedImage
            
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            userImage.image = originalImage
            coverImage.image = originalImage
        }
        dismiss(animated: true, completion: nil)
            
    }
}

extension ShowProfileViewController {
    
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



