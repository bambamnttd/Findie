//
//  MiniReviewCell.swift
//  thesisApp
//
//  Created by Bambam on 1/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

class MiniReviewCell: UICollectionViewCell {

    @IBOutlet weak var starRate: UIImageView!
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var timeReview: UILabel!
    @IBOutlet weak var textReview: UITextView!
    
    let showReviewCell = ShowReviewCollectionViewCell()

    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = .white
        userImage.layer.cornerRadius = userImage.bounds.height / 2
        userImage.clipsToBounds = true
        
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 5
        let attributes = [NSAttributedString.Key.paragraphStyle: style]
        textReview.attributedText = NSAttributedString(string: textReview.text, attributes: attributes)
        textReview.font = UIFont(name: "Helvetica Neue", size: 15)
        textReview.textColor = .init(red: 36/255, green: 36/255, blue: 36/255, alpha: 1)
    }
}
