//
//  CollectRewardCell.swift
//  thesisApp
//
//  Created by Bambam on 6/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

class CollectRewardCell: UICollectionViewCell {
    
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var giftImage: UIImageView!
    @IBOutlet weak var stampImage: UIImageView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.masksToBounds = true
        self.layer.cornerRadius = self.frame.size.width / 2
        self.layer.borderWidth = 2.5
        self.layer.borderColor = UIColor.white.cgColor
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        //hide or reset anything you want hereafter, for example
        self.layer.borderWidth = 2.5
        self.layer.borderColor = UIColor.white.cgColor
        self.backgroundColor = UIColor.init(white: 1, alpha: 0)
        pointLabel.text = "1"
        giftImage.image = UIImage(named: "gift_white.png")
        stampImage.isHidden = true
    }

}
