//
//  MyQueueCell.swift
//  thesisApp
//
//  Created by Bambam on 3/4/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit

protocol CalledDelegate : class {
    func called(myqueue: MyQueue)
}

class MyQueueCell: UITableViewCell {
    
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var ticketImage: UIImageView!
    @IBOutlet weak var queueNumberLabel: UILabel!
    @IBOutlet weak var waitQueueLabel: UILabel!
    @IBOutlet weak var waitTitleLabel: UILabel!
    @IBOutlet weak var queueTitleLabel: UILabel!
    @IBOutlet weak var fadeView: UIView!
    
    var data: MyQueue!
    var delegate: CalledDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        logoImage.layer.cornerRadius = 5
        fadeView.layer.cornerRadius = 5
        print("\(data) print")
//        whenCalledQueue()
    }
    
    func whenCalledQueue() {
        print(data.status)
//        if data.status == "called" {
//            delegate?.called(myqueue: data)
//        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        //hide or reset anything you want hereafter, for example
//        logoImage.image = UIImage()
//        queueNumberLabel.text = ""
//        waitQueueLabel.text = ""
//    }

}
