//
//  AgentViewController.swift
//  immeta
//
//  Created by ribencong on 2021/9/3.
//

import UIKit
import StoreKit
import ChatLib

class AgentViewController: UIViewController {
    
        var products: [SKProduct] = []
        var selectedId: Int = 0
        @IBOutlet weak var collectionView: UICollectionView!
        @IBOutlet weak var buyBtn: UIButton!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                hideKeyboardWhenTappedAround()
                collectionView.delegate = self
                collectionView.dataSource = self
                
                let layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .horizontal
                layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 5)
                
                collectionView.collectionViewLayout = layout
        }
        
        override func viewWillAppear(_ animated: Bool) {
                
                self.showIndicator(withTitle: "", and: "loading products".locStr)
                
                licenseProducts.store.requestProducts { res in
                        defer{
                                self.hideIndicator()
                        }
                        
                        guard let products = res, products.count > 0 else {
                                self.toastMessage(title: "load products failed".locStr)
                                return
                        }
                        
                        let sortedRes = products.sorted(by: { a, b in
                                return a.price.decimalValue < b.price.decimalValue
                        })
                        
                        self.products = sortedRes
                        DispatchQueue.main.async {
                                self.collectionView.reloadData()
                                self.setupBuyBtn()
                        }
                }
        }
    
        @IBAction func CloseStoreView(_ sender: UIButton) {
                self.dismiss(animated: true)
        }
        
        @IBAction func backBarBtn(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }

        @IBAction func buyLicense(_ sender: UIButton) {
                
                licenseProducts.store.buyProduct(products[selectedId]) {tx, error in
                        
                        if let err = error {
                                self.toastMessage(title: err.localizedDescription)
                                return err
                        }
                        
                        guard let transaction = tx,
                                let txid = transaction.transactionIdentifier else{
                                self.toastMessage(title: "Buy failed".locStr)
                                return NJError.account("iap buy empty tx") as NSError
                        }
                        
                        let payment = transaction.payment
                        guard let userAddress = payment.applicationUsername else{
                                return NJError.account("iap empty blockchain address in payment") as NSError
                        }
                        
                        return self.writeToBlockChain(payment.productIdentifier, txid, userAddress)
                }
        }
        
        private func writeToBlockChain(_ productID:String,_ txid:String, _ address:String) ->NSError?{
                var err:NSError? = nil
                self.showIndicator(withTitle: "", and: "Writing BlockChain".locStr)
                ServiceDelegate.workQueue.async {
//                        let amount =
                        ChatLibTransferForIap(address, txid, 10, &err)
                        DispatchQueue.main.async {
                                self.dismiss(animated: true)
                        }
                }
                return err
        }
        
        func setupBuyBtn() {
                guard products.count > 0  else{
                        return
                }
                
                let pdt = products[selectedId]
                let text = String((pdt.priceLocale.currencySymbol ?? "")+pdt.price.toString() + " " + "Buy Now".locStr)
                buyBtn.setTitle(text, for: .normal)
                
        }
}

extension AgentViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return products.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                guard let ncell = collectionView.dequeueReusableCell(withReuseIdentifier: "normalCollectCell", for: indexPath) as? LicenseCollectionViewCell else {
                        return UICollectionViewCell()
                }
                if selectedId == indexPath.row {
                        ncell.contentView.borderColor = UIColor(hex: "FFD477")
                        ncell.contentView.backgroundColor = UIColor(hex: "FFFAF1")
                } else {
                        ncell.contentView.borderColor = UIColor(hex: "EDEDED")
                        ncell.contentView.backgroundColor = UIColor(hex: "FFFFFF")
                }
                if products.count > indexPath.row {
                        let pdt = products[indexPath.row]
                        ncell.initCell(product: pdt)
                }
                return ncell
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
                return CGSize(width: 110, height: 128)
        }
        
        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
                self.selectedId = indexPath.row
                self.collectionView.reloadData()
                setupBuyBtn()
        }
}
