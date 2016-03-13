//
//  PantryCollectionViewCell.swift
//  Vanfiider
//
//  Created by Kang Shiang Yap on 2016-03-04.
//  Copyright © 2016 Fiidup. All rights reserved.
//

import Foundation
import UIKit
import FastImageCache

class PantryCollectionViewCell : UICollectionViewCell {
    var photoInfo: PhotoInfo?
    var profilePictureInfo: PhotoInfo?
    @IBOutlet var image: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    func loadItem(image image: NSURL, shouldDelete: Bool) {

    }
    
}