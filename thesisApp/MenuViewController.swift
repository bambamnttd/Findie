//
//  MenuViewController.swift
//  thesisApp
//
//  Created by Bambam on 22/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

class MenuViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let db = Firestore.firestore()
    var collectionViewFlowLayout : UICollectionViewFlowLayout!
    let cellIdentifier = "MenuCollectionViewCell"
    var items = [String]()
    var selectedImage = String()
    let getdata = GetData()
    var cafe_id = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getAllPicURL()
        setupCollectionView()
        setupNavigationBarItems()
        navigationItem.title = "เมนู"
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        let nib = UINib(nibName: "MenuCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: cellIdentifier)
    }
    
    func getAllPicURL() {
        db.collection("cafe_image").document(cafe_id).getDocument { (document, error) in
            if let document = document, document.exists {
                let dd = document.get("cafe_menu") as! [String]
                if dd.count > 0 {
                    self.items = dd
                }
            }
            else {
                print("Document does not exist")
            }
            self.collectionView.reloadData()
        }
    }
}

extension MenuViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let numberOfItemPerRow: CGFloat = 2
        let interItemSpacing: CGFloat = 1
        let width = (collectionView.frame.width - (numberOfItemPerRow * interItemSpacing)) / numberOfItemPerRow
        return CGSize(width: width, height: 275)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! MenuCollectionViewCell
        getdata.getImage(imageURL: items[indexPath.item], imageView: cell.menuImage)
        //cell.imageView.image = UIImage(named: items[indexPath.item].picURL)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedImage = items[indexPath.item]
        let showImageVC = storyboard?.instantiateViewController(withIdentifier: "ShowImageVC") as! ShowImageViewController
        showImageVC.indexPath = indexPath
        showImageVC.items = items
        self.navigationController?.pushViewController(showImageVC, animated: true)
    }
}

