//
//  AgentViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/3.
//

import UIKit

class AgentViewController: UIViewController {
    
        var license: String?
        @IBOutlet weak var collectionView: UICollectionView!
        @IBOutlet weak var serviceId: UILabel!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                hideKeyboardWhenTappedAround()
                collectionView.delegate = self
                collectionView.dataSource = self
        }
    
        @IBAction func backBarBtn(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }

        @IBAction func copyId(_ sender: UIButton) {
                if let text = serviceId.text {
                        UIPasteboard.general.string = text
                        self.toastMessage(title: "Copy Success")
                }
        }
}

extension AgentViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                return 2
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                let ncell = collectionView.dequeueReusableCell(withReuseIdentifier: "normalCollectCell", for: indexPath)
                let vcell = collectionView.dequeueReusableCell(withReuseIdentifier: "vipCollectCell", for: indexPath)
                if indexPath.row == 0 {
                        return ncell
                }
                if indexPath.row == 1 {
                        return vcell
                }
                return UICollectionViewCell()
        }
        
        
}
