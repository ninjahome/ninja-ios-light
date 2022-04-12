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
}

public typealias ProductsRequestCompletionHandler = (_ products: [SKProduct]?) -> Void
public typealias ProductPurchaseCompletionHandler = (_ transaction: SKPaymentTransaction?, _ err:NSError?) -> Void

// MARK: - IAPManager
public class IAPManager: NSObject  {
        private let productIdentifiers: Set<ProductID>
        private var productsRequest: SKProductsRequest?
        private var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
        private var productPurchaseCompletionHandler: ProductPurchaseCompletionHandler?
        
        public init(productIDs: Set<ProductID>) {
                self.productIdentifiers = productIDs
                super.init()
                restorePurchases()
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
                print("------>>>Buying... \(product.productIdentifier)")
                
                productPurchaseCompletionHandler = completionHandler
                
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
        
        public func fetchreceiptData(){
                if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
                    FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {

                    do {
                        let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                        print(receiptData)

                        let receiptString = receiptData.base64EncodedString(options: [])

                            print("------>>>receiptString=>", receiptString)
                    }
                    catch { print("------>>>Couldn't read receipt data with error: " + error.localizedDescription) }
                }
        }
}

// MARK: - SKProductsRequestDelegate
extension IAPManager: SKProductsRequestDelegate {
        
        public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
                print("------>SKProductsRequestDelegate callback: \(response.products.count)")
                productsRequestCompletionHandler?(response.products)
                clearRequestAndHandler()
        }
        
        public func request(_ request: SKRequest, didFailWithError error: Error) {
                print("------>SKProductsRequestDelegate Error: \(error.localizedDescription)")
                productsRequestCompletionHandler?([])
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
                
                print("------>>>complete... \(identifier)")
                productPurchaseCompletionHandler?(transaction, nil)
                clearHandler()
                SKPaymentQueue.default().finishTransaction(transaction)
        }
        
        private func restore(transaction: SKPaymentTransaction) {
                guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
                
                print("------>>>restore... \(productIdentifier)")
                SKPaymentQueue.default().finishTransaction(transaction)
        }
        
        private func fail(transaction: SKPaymentTransaction) {
                guard let transactionError = transaction.error as NSError?,
                   transactionError.code != SKError.paymentCancelled.rawValue  else{
                        return
                }
                print("------>>>fail... \(transactionError.localizedDescription)")
                productPurchaseCompletionHandler?(nil, transactionError)
                clearHandler()
                SKPaymentQueue.default().finishTransaction(transaction)
        }
        
        private func clearHandler() {
                productPurchaseCompletionHandler = nil
        }
}
