//
//  RewardMenuCell.swift
//  thesisApp
//
//  Created by Bambam on 16/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

class RewardMenuCell: UICollectionViewCell {

    @IBOutlet weak var menuLabel: UILabel!
    
    override func awakeFromNib() {
        menuLabel.alpha = 0.6
    }
    
    func setupCell(text: String) {
        menuLabel.text = text
    }
    
    override var isSelected: Bool {
        didSet {
            menuLabel.alpha = isSelected ? 1.0 : 0.6
        }
    }
}
