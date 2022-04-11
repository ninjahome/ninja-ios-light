//
//  LicensePurchaseManager.swift
//  immeta
//
//  Created by ribencong on 2022/3/24.
//

import Foundation
import StoreKit

public typealias ProductID = String
public struct licenseProducts {
        public static let oneMonth = "com.immeta.chat.license.30day"
        public static let threeMonths = "com.immeta.chat.license.90day"
        public static let halfYear = "com.immeta.chat.license.180day"
        public static let oneYear = "com.immeta.chat.license.360day"
        
        public static let store = IAPManager(productIDs: licenseProducts.productIDs)
        private static let productIDs: Set<ProductID> = [licenseProducts.oneMonth,
                                                         licenseProducts.threeMonths,
                                                         licenseProducts.halfYear,
                                                         licenseProducts.oneYear]
        
        public static func getLicenseDays(by id: String) -> Int {
                if id == licenseProducts.oneMonth {
                        return 30
                }
                if id == licenseProducts.threeMonths {
                        return 90
                }
                if id == licenseProducts.halfYear {
                        return 180
                }
                if id == licenseProducts.oneYear {
                        return 360
                }
                return 0
        }
}

public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> Void
public typealias ProductPurchaseCompletionHandler = (_ success: Bool, _ productId: ProductID?) -> Void

// MARK: - IAPManager
public class IAPManager: NSObject  {
        private let productIdentifiers: Set<ProductID>
        private var productsRequest: SKProductsRequest?
        private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
        private var productPurchaseCompletionHandler: ProductPurchaseCompletionHandler?
        
        public init(productIDs: Set<ProductID>) {
                self.productIdentifiers = productIDs
                super.init()
                SKPaymentQueue.default().add(self)
        }
}

// MARK: - StoreKit API
extension IAPManager {
        public func requestProducts(_ completionHandler: @escaping ProductsRequestCompletionHandler) {
                productsRequest?.cancel()
                productsRequestCompletionHandler = completionHandler
                
                productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
                productsRequest!.delegate = self
                productsRequest!.start()
        }
        
        public func buyProduct(_ product: SKProduct, _ completionHandler: @escaping ProductPurchaseCompletionHandler) {
                productPurchaseCompletionHandler = completionHandler
                print("------>>>Buying \(product.productIdentifier)...")
                
                let payment = SKMutablePayment(product: product)
                payment.applicationUsername = Wallet.shared.Addr
                SKPaymentQueue.default().add(payment)
        }
        
        public class func canMakePayments() -> Bool {
                return SKPaymentQueue.canMakePayments()
        }
        
        public func restorePurchases() {
                SKPaymentQueue.default().restoreCompletedTransactions()
        }
}

// MARK: - SKProductsRequestDelegate
extension IAPManager: SKProductsRequestDelegate {
        public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
                print("Loaded list of products...")
                let products = response.products
                guard !products.isEmpty else {
                        print("Product list is empty...!")
                        print("Did you configure the project and set up the IAP?")
                        productsRequestCompletionHandler?(false, nil)
                        return
                }
                productsRequestCompletionHandler?(true, products)
                clearRequestAndHandler()
                for p in products {
                        print("Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
                }
        }
        
        public func request(_ request: SKRequest, didFailWithError error: Error) {
                print("Failed to load list of products.")
                print("Error: \(error.localizedDescription)")
                productsRequestCompletionHandler?(false, nil)
                clearRequestAndHandler()
        }
        
        private func clearRequestAndHandler() {
                productsRequest = nil
                productsRequestCompletionHandler = nil
        }
}

// MARK: - SKPaymentTransactionObserver
extension IAPManager: SKPaymentTransactionObserver {
        public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
                for transaction in transactions {
                        switch (transaction.transactionState) {
                        case .purchased:
                                complete(transaction: transaction)
                                break
                        case .failed:
                                fail(transaction: transaction)
                                break
                        case .restored:
                                restore(transaction: transaction)
                                break
                        case .deferred:
                                break
                        case .purchasing:
                                break
                        @unknown default:
                                break
                        }
                }
        }
        
        private func complete(transaction: SKPaymentTransaction) {
                let identifier = transaction.payment.productIdentifier
                Wallet.shared.AddLicense(by: licenseProducts.getLicenseDays(by: identifier))
                
                productPurchaseCompleted(identifier: identifier)
                NotificationCenter.default.post(name: NotifyLicenseChanged, object: nil)
                SKPaymentQueue.default().finishTransaction(transaction)
        }
        
        private func restore(transaction: SKPaymentTransaction) {
//                guard let payment = transaction.original?.payment else { return }
//
//                let productIdentifier = payment.productIdentifier
//                print("restore... \(productIdentifier):::\(payment)")
//                productPurchaseCompleted(identifier: productIdentifier)
//                SKPaymentQueue.default().finishTransaction(transaction)
        }
        
        private func fail(transaction: SKPaymentTransaction) {
                if let transactionError = transaction.error as NSError?,
                   let localizedDescription = transaction.error?.localizedDescription,
                   transactionError.code != SKError.paymentCancelled.rawValue {
                        print("------>>>Transaction Error: \(localizedDescription)")
                }
                
                productPurchaseCompletionHandler?(false, nil)
                SKPaymentQueue.default().finishTransaction(transaction)
                clearHandler()
        }
        
        private func productPurchaseCompleted(identifier: ProductID?) {
                guard let identifier = identifier else { return }
                productPurchaseCompletionHandler?(true, identifier)
                clearHandler()
        }
        
        private func clearHandler() {
                productPurchaseCompletionHandler = nil
        }
}
