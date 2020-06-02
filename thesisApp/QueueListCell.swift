//
//  QueueCell.swift
//  thesisApp
//
//  Created by Bambam on 12/3/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

class QueueListCell: UITableViewCell {
    
    @IBOutlet weak var cafenameLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var queueTotalLabel: UILabel!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var fadeView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        logoImage.layer.cornerRadius = logoImage.bounds.height / 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
