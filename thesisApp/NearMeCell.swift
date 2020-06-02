//
//  HomeCollectionViewCell.swift
//  thesisApp
//
//  Created by Bambam on 21/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

class NearMeCell: UICollectionViewCell {

    @IBOutlet weak var cafeImage: UIImageView!
    @IBOutlet weak var cafeNameLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var reviewTotalLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = .white
        self.cafeImage.layer.cornerRadius = 3
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        cafeImage.image = UIImage()
        cafeNameLabel.text = ""
        distanceLabel.text = ""
        ratingLabel.text = ""
        reviewTotalLabel.text = ""
    }
}

class PromotionHomeCell: UICollectionViewCell {
    @IBOutlet weak var promotionImage: UIImageView!
    @IBOutlet weak var promotionTopicLabel: UILabel!
    @IBOutlet weak var cafeNameLabel: UILabel!
}
