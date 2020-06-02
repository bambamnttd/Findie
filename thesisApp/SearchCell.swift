//
//  SearchCell.swift
//  thesisApp
//
//  Created by Bambam on 7/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

class SearchCell: UITableViewCell {
    
    @IBOutlet weak var cafeImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var styleLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var reviewTotalLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var seperator: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.cafeImage.layer.cornerRadius = 3
        seperator.backgroundColor = .init(red: 240/255, green: 240/255, blue: 241/255, alpha: 1)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
