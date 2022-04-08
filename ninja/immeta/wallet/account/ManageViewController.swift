//
//  ManageViewController.swift
//  immeta
//
//  Created by 郭晓芙 on 2021/5/22.
//

import UIKit

class ManageViewController: UIViewController {
        
        override func viewDidLoad() {
                super.viewDidLoad()
                let item = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
                self.navigationItem.backBarButtonItem = item
        }
}

extension ManageViewController: ScannerViewControllerDelegate {
        
        func codeDetected(code: String) {
                
                print("------>>>\(code)")
                guard let addr = Wallet.shared.serializeWalletJson(cipher: code) else {
                        self.toastMessage(title: "Invaild immeta wallet address".locStr)
                        return
                }
                
                self.showPwdInput(title: "Import account".locStr, placeHolder: "Please input password".locStr) {[weak self] (auth, isOK) in
                        guard let pwd = auth, isOK else{
                                return
                        }
                        
                        ServiceDelegate.ImportNewAccount(wJson: code, addr: addr, pwd: pwd, parent: self!) {
                                DispatchQueue.main.async {
                                        self?.navigationController?.popToRootViewController(animated: true)
                                }
                        }
                }
        }
}

extension ManageViewController{
        
        @IBAction func createWallet(_ gesture: UITapGestureRecognizer) {
                
                let vc = instantiateViewController(vcID: "CreateWalletVC") as! NewWalletViewController
                self.navigationController?.pushViewController(vc, animated: true)
        }
        
        @IBAction func exportAccount(_ gesture: UITapGestureRecognizer) {
                
                
                guard let walletJson = Wallet.shared.wJson else{
                        self.toastMessage(title: "Save Failed".locStr)
                        return
                }
                
                self.showIndicator(withTitle: "", and: "exporting".locStr)
                ServiceDelegate.workQueue.async {
                        guard let walletImg = self.generateQRCode(from: walletJson)else{
                                self.hideIndicator()
                                self.toastMessage(title: "Generat qr image failed".locStr)
                                return
                        }
                        print("------>>>walletJson \(walletJson)")
                        UIImageWriteToSavedPhotosAlbum(walletImg, nil, nil, nil)
                        self.hideIndicator()
                        self.toastMessage(title: "Save success".locStr, duration: 1)
                }
        }
        @IBAction func scanner(_ gesture: UITapGestureRecognizer) {
                let vc = instantiateViewController(vcID: "ScannerVC") as! ScannerViewController
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
        }
}
