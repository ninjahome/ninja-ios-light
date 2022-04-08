//
//  AgentViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/3.
//

import UIKit
import StoreKit

class AgentViewController: UIViewController {
    
        var products: [SKProduct] = []
        var selectedId: Int = 0
        @IBOutlet weak var collectionView: UICollectionView!
//        @IBOutlet weak var serviceId: UILabel!
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
                buyBtnContent()
        }
        
        override func viewWillAppear(_ animated: Bool) {
                licenseProducts.store.restorePurchases()
                licenseProducts.store.requestProducts { [weak self] success, res in
                        guard let self = self else { return }
                        guard success else { return }
                        let sortedRes = res?.sorted(by: { a, b in
                                return a.price.decimalValue < b.price.decimalValue
                        })
                        self.products = sortedRes ?? []
                        DispatchQueue.main.async {
                                self.collectionView.reloadData()
                                self.buyBtnContent()
                        }
                }
        }
    
        @IBAction func backBarBtn(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }

//        @IBAction func copyId(_ sender: UIButton) {
//                if let text = serviceId.text {
//                        UIPasteboard.general.string = text
//                        self.toastMessage(title: "Copy Success".locStr)
//                }
//        }
        
        @IBAction func buyLicense(_ sender: UIButton) {
                buyProduct(by: selectedId)
        }
        
        func buyProduct(by id: Int) {
                licenseProducts.store.buyProduct(products[id]) { [weak self] success, productId in
                        guard let self = self else { return }
                        guard success else {
                                return
                        }
                        
                        self.toastMessage(title: "Buy success!")
                }
        }
        
        func buyBtnContent() {
                if products.count > 0 {
                        let pdt = products[selectedId]
                        let text = String((pdt.priceLocale.currencySymbol ?? "")+pdt.price.toString()+"立即激活")
                        buyBtn.setTitle(text, for: .normal)
                }
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
                buyBtnContent()
        }
}