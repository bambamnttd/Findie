//
//  ShowMenuCell.swift
//  thesisApp
//
//  Created by Bambam on 22/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

class ShowImageCell: UICollectionViewCell, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var fullMenuImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.scrollView.delegate = self
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 3.5
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return fullMenuImage
    }
    
}
