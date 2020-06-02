//
//  CardListCell.swift
//  thesisApp
//
//  Created by Bambam on 16/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

class CardListCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var cardImage: UIImageView!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var bgCardView: UIView!
    @IBOutlet weak var pointLabel: UILabel!
    @IBOutlet weak var expDateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        logoImage.layer.cornerRadius = logoImage.bounds.height / 2
        logoImage.clipsToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
