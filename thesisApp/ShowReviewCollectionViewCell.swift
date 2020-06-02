//
//  ShowReviewCollectionViewCell.swift
//  thesisApp
//
//  Created by Bambam on 23/1/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

protocol AlertDelegate: class {
    func presentAlert(review_id: String, cafe_id: String)
}

class ShowReviewCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userImage: UIImageView!
    @IBOutlet weak var starRate: UIImageView!
    @IBOutlet weak var timeReview: UILabel!
    @IBOutlet weak var textReview: UITextView!
    @IBOutlet weak var moreButton: UIButton!
    
    var alertDelegate : AlertDelegate?
    var data : ReviewData!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        moreButton.addTarget(self, action: #selector(sendDataBack), for: .touchUpInside)
    }
    
    @objc func sendDataBack() {
        let review_id = data.review_id
        let cafe_id = data.cafe_id
        alertDelegate?.presentAlert(review_id: review_id, cafe_id: cafe_id)
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
