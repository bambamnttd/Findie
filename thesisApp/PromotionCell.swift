//
//  PromotionCell.swift
//  thesisApp
//
//  Created by Bambam on 15/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

class PromotionCell: UITableViewCell {
    @IBOutlet weak var topicLabel: UILabel!
    @IBOutlet weak var cafenameLabel: UILabel!
    @IBOutlet weak var promotionImage: UIImageView!
    @IBOutlet weak var expiredDateLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
//        bgView.layer.borderColor = UIColor.init(red: 230/255, green: 230/255, blue: 230/255, alpha: 1).cgColor
//        bgView.layer.borderWidth = 1
        setBackGroundView()
    }
    
    func setBackGroundView() {
        bgView.layer.cornerRadius = 5
        bgView.layer.shadowColor = UIColor.gray.cgColor
        bgView.layer.shadowOffset = CGSize(width: 2, height: 2)
        bgView.layer.shadowRadius = 3.5
        bgView.layer.shadowOpacity = 0.4
        bgView.layer.shadowPath = UIBezierPath(rect: bgView.bounds).cgPath
        bgView.layer.shouldRasterize = true
        bgView.layer.rasterizationScale = UIScreen.main.scale
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
