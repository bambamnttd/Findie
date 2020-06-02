//
//  FavoriteCell.swift
//  thesisApp
//
//  Created by Bambam on 12/2/20.
//  Copyright © 2020 Bambam. All rights reserved.
//

import UIKit
import Firebase

class FavoriteCell: UITableViewCell {

    @IBOutlet weak var cafeImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var reviewTotalLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var seperator: UIImageView!
    
    let db = Firestore.firestore()
    var data: FavoriteData!
    
    @IBAction func unFavorite(_ sender: UIButton) {
        let cafe_id = data.cafe_id
        favoriteButton.setImage(UIImage(named: "bookmark1.png"), for: .normal)
        db.collection("favorite").whereField("cafe_id", isEqualTo: cafe_id).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let favid = document.documentID
                    self.db.collection("favorite").document(favid).delete() { err in
                        if let err = err {
                            print("Error removing document: \(err)")
                        } else {
                            print("Document successfully removed!")
                        }
                    }
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        self.cafeImage.layer.cornerRadius = 3
        seperator.backgroundColor = .init(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
