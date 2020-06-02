//
//  LoginViewController.swift
//  thesisApp
//
//  Created by Bambam on 4/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    @IBAction func close(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //ทำให้อยู่ตรงกลาง
        loginButton.center.x = self.view.center.x
        emailTextField.center.x = self.view.center.x
        passwordTextField.center.x = self.view.center.x
        
        emailTextField.setBottomBorder()
        passwordTextField.setBottomBorder()
        loginButton.layer.cornerRadius = 5
        
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        
        self.hideKeyboard()
    }
    
    @objc func login(_ sender: Any) {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { email, error in
            if error == nil && email != nil {
                print("เข้าสู่ระบบสำเร็จ")
                self.dismiss(animated: true, completion: nil)
            } else {
                print("เข้าสู่ระบบไม่สำเร็จ: \(error! .localizedDescription)")
                let alert = UIAlertController(title: "เข้าสู่ระบบไม่สำเร็จ", message: "อีเมลหรือรหัสผ่านไม่ถูกต้อง", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "ตกลง", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let email = Auth.auth().currentUser {
            self.performSegue(withIdentifier: "toHomeScreen", sender: self)
        }
    }
    
}
