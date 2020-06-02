//
//  TabBarController.swift
//  thesisApp
//
//  Created by Bambam on 15/5/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

class TabBarController: UITabBarController {
    
    let db = Firestore.firestore()
    var count = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        UNUserNotificationCenter.current().delegate = self
        if Auth.auth().currentUser != nil {
            checkQueueCalled()
        }
    }
    
    func checkQueueCalled() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("queue").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            print(documents.count)
            for document in documents {
                let uid2 = document.get("uid") as! String
                if uid2 == uid {
                    let queue_id = document.documentID
                    let queue_no = document.get("queue_no") as! String
                    let number_people = document.get("number_people") as! Int
                    let cafe_id = document.get("cafe_id") as! String
                    let cafename_en = document.get("cafename_en") as! String
                    let timeInterval = document.get("timeInterval") as! Double
                    let status = document.get("status") as! String
                    let category = String(queue_no.prefix(1))
                    let waitqueue = self.getWaitQueue(documents: documents, createdate: timeInterval, category: category, cafe_id: cafe_id)
                    if waitqueue == 3 {
                        self.presentNotification(title: "ใกล้จะถึงคิวของคุณแล้ว by \(cafename_en)", body: "หมายเลขคิว \(queue_no) จำนวน \(number_people) ที่นั่ง")
                        break
                    }
                    if status == "called" {
                        self.presentNotification(title: "ถึงคิวของคุณแล้ว by \(cafename_en)", body: "หมายเลขคิว \(queue_no) จำนวน \(number_people) ที่นั่ง")
                        if let tabItems = self.tabBar.items {
                            let tabItem = tabItems[2]
                            tabItem.badgeValue = "1"
                            print("ถูกเรียกแล้ว")
                        }
                    } else if status == "passed" {
                        self.presentNotification(title: "คิวของคุณถูกยกเลิก by \(cafename_en)", body: "")
                        if let tabItems = self.tabBar.items {
                            let tabItem = tabItems[2]
                            tabItem.badgeValue = "1"
                        }
                    }
                }
            }
        }
    }
    
    func presentNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }
    }
    
    func getWaitQueue(documents: [QueryDocumentSnapshot], createdate: Double, category: String, cafe_id: String) -> Int {
        count = 0
        for doc in documents {
            let c_id = doc.get("cafe_id") as! String
            let time = doc.get("timeInterval") as! Double
            let q_no = doc.get("queue_no") as! String
            let status = doc.get("status") as! String
            if c_id == cafe_id && q_no.contains(category) && status == "booked"{
                if time < createdate {
                    print("category = \(category)")
                    count += 1
                }
            }
        }
        print(count)
        return count
    }
}

extension TabBarController: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("bambam")
        self.selectedIndex = 2
        completionHandler()
    }
}
