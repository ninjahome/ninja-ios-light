//
//  LicenseCollectionViewCell.swift
//  immeta
//
//  Created by 郭晓芙 on 2022/3/28.
//

import UIKit

class LicenseCollectionViewCell: UICollectionViewCell {
        @IBOutlet weak var licenseTime: UILabel!
        @IBOutlet weak var licensePrice: UILabel!
        
        override func prepareForReuse() {
                licenseTime.text = "time"
                licensePrice.text = "price"
        }
        
        func initCell(time: String, price: String) {
                licensePrice.text = price
                licenseTime.text = time
        }
}
