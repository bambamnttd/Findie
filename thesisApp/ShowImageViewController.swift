//
//  ShowMenuViewController.swift
//  thesisApp
//
//  Created by Bambam on 22/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import FirebaseUI

class ShowImageViewController: UIViewController {
    
    @IBOutlet weak var menuImageCollectionView: UICollectionView!
    
    var menuImageView: UIImageView!
    var scrollView: UIScrollView!
    var indexPath: IndexPath!
    var items: [String]!
    var cafename_en = String()
    let countCells = 1
    let cellIdentifier = "ShowImageCell"
    let getData = GetData()
    var tapped = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        setupScrollView()
        setCollectionView()
//        setImageView()
        setupNavigationBarItems()
        navigationItem.title = cafename_en
        self.navigationController?.navigationBar.setBackgroundImage(UIColor.white.as1ptImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        navigationController?.hidesBarsOnSwipe = false
//        navigationController?.hidesBarsOnTap = true
//    }

    func setImageView() {
        let imageTap = UITapGestureRecognizer(target: self, action: #selector(hideNavbarAndTabbar))
        menuImageCollectionView.isUserInteractionEnabled = true
        menuImageCollectionView.addGestureRecognizer(imageTap)
    }
    
    @objc func hideNavbarAndTabbar() {
        if tapped == 0 {
            self.navigationController?.navigationBar.setBackgroundImage(UIColor.black.as1ptImage(), for: .default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationItem.setHidesBackButton(true, animated: false)
            self.tabBarController?.tabBar.isHidden = true
            tapped = 1
        }
        else {
            self.navigationController?.navigationBar.shadowImage = UIColor.init(red: 213/255, green: 103/255, blue: 82/255, alpha: 1).as1ptImage()
            self.navigationController?.navigationBar.setBackgroundImage(UIColor.clear.as1ptImage(), for: .default)
            self.navigationItem.setHidesBackButton(false, animated: false)
            self.tabBarController?.tabBar.isHidden = false
            tapped = 0
        }
    }
    
    func setCollectionView() {
        menuImageCollectionView.backgroundColor = .white
        menuImageCollectionView.delegate = self
        menuImageCollectionView.dataSource = self
        menuImageCollectionView.register(UINib(nibName: "ShowImageCell", bundle: nil), forCellWithReuseIdentifier: cellIdentifier)
        menuImageCollectionView.performBatchUpdates(nil) { (result) in
            self.menuImageCollectionView.scrollToItem(at: self.indexPath, at: .centeredHorizontally, animated: false)
        }
    }
}

extension ShowImageViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let frameCV = view.frame
        let widthCell = frameCV.width / CGFloat(countCells)
        let heightCell = frameCV.height / CGFloat(countCells)
        return CGSize(width: widthCell, height: heightCell)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ShowImageCell
        getData.getImage(imageURL: items[indexPath.item], imageView: cell.fullMenuImage)
        return cell
    }

}
