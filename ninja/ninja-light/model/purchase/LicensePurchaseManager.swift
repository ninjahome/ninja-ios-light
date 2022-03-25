//
//  LicensePurchaseManager.swift
//  immeta
//
//  Created by 郭晓芙 on 2022/3/24.
//

import Foundation
import StoreKit

enum purchaseTyps: String, CaseIterable {
        case oneMonth = "com.immeta.chat.license.1month"
        case threeMonths = "com.immeta.chat.license.3month"
        case halfYear = "com.immeta.chat.license.6month"
        case oneYear = "com.immeta.chat.license.12month"
}
//
//class LicensePurchase: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
//        private var products = [SKProduct]()
//
//        private func fetchProducts() {
//                let request = SKProductsRequest(productIdentifiers: Set(purchaseTyps.allCases.compactMap({ $0.rawValue })))
//                request.delegate = self
//
//                request.start()
//
////                SKPaymentQueue.default().add(self)
//        }
//
//        func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
//                ServiceDelegate.workQueue.async {
//                        print("Count: \(response.products.count)")
//                        self.products = response.products
//                }
//        }
//
//        func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
//                <#code#>
//        }
//}
