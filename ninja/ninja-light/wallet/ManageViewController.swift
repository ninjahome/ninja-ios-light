//
//  ManageViewController.swift
//  ninja-light
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
        
        @IBAction func exportAccount(_ sender: UIButton) {
                if let walletJson = Wallet.shared.wJson,
                   let walletImg = generateQRCode(from: walletJson) {
                        print("walletJson \(walletJson)")
                        UIImageWriteToSavedPhotosAlbum(walletImg, nil, nil, nil)
                        self.toastMessage(title: "Save success")
                } else {
                        self.toastMessage(title: "Save Failed")
                }
        }
        @IBAction func scanner(_ sender: UIButton) {
                let vc = instantiateViewController(vcID: "ScannerVC") as! ScannerViewController
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
        }
        
        @IBAction func createWallet(_ sender: UIButton) {
                let vc = instantiateViewController(vcID: "CreateWalletVC") as! NewWalletViewController
                self.navigationController?.pushViewController(vc, animated: true)
        }
        
}

extension ManageViewController: ScannerViewControllerDelegate {
        
        func codeDetected(code: String) {
                
                print("------>>>\(code)")
                guard let addr = Wallet.shared.serializeWalletJson(cipher: code) else {
                        self.toastMessage(title: "invaild ninja wallet address")
                        return
                }
                
                self.showPwdInput(title: "请输入密码导入账号", placeHolder: "请输入密码") {[weak self] (auth, isOK) in
                        guard let pwd = auth, isOK else{
                                return
                        }
                        
                        ServiceDelegate.ImportNewAccount(wJson: code, addr: addr, pwd: pwd, parent: self!) {
//                                ServiceDelegate.InitService()//TODO:: need reload old message?
                                self?.navigationController?.popToRootViewController(animated: true)
                        }
                }
        }
}
