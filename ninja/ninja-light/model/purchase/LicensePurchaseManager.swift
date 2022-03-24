//
//  LicensePurchaseManager.swift
//  immeta
//
//  Created by 郭晓芙 on 2022/3/24.
//

import Foundation
import StoreKit

enum purchaseTyps: String {
        case oneMonth = "com.immeta.chat.license.1month"
        case threeMonths = "com.immeta.chat.license.3month"
        case halfYear = "com.immeta.chat.license.6month"
        case oneYear = "com.immeta.chat.license.12month"
}

class LicensePurchase {
        private var products = [SKProduct]()
}
