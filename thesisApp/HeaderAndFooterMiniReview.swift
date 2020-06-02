//
//  HeaderMiniReview.swift
//  thesisApp
//
//  Created by Bambam on 2/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import Foundation
import UIKit

class HeaderMiniReview : UICollectionReusableView {
    
    @IBOutlet weak var headerLabel: UILabel! {
        didSet {
            if headerLabel == nil {
                print("Label set to nil!")
            }
        }
    }
}

class FooterMiniReview : UICollectionReusableView {
    
    @IBOutlet weak var moreButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        moreButton.setTitle("ดูทั้งหมด", for: .normal)
    }
}
