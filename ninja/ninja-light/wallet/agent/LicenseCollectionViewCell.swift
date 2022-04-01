//
//  LicenseCollectionViewCell.swift
//  immeta
//
//  Created by 郭晓芙 on 2022/3/28.
//

import UIKit
import StoreKit

class LicenseCollectionViewCell: UICollectionViewCell {
        @IBOutlet weak var licenseTime: UILabel!
        @IBOutlet weak var licensePrice: UILabel!
        @IBOutlet weak var currencyLable: UILabel!
        
        override func prepareForReuse() {
                licenseTime.text = "time"
                licensePrice.text = "price"
                currencyLable.text = ""
        }
        
        func initCell(product: SKProduct) {
                licensePrice.text = product.price.toString()
                licenseTime.text = product.localizedTitle
                currencyLable.text = product.priceLocale.currencySymbol
        }
}
