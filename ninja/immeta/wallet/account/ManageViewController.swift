//
//  ManageViewController.swift
//  immeta
//
//  Created by ribencong on 2021/5/22.
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
                                        NotificationCenter.default.post(name:NotifyContactChanged, object: nil)
                                        NotificationCenter.default.post(name:NotifyGroupChanged, object: nil)
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
                
                
                guard let vc = instantiateViewController(vcID: "BackupGuideViewControllerSID") as? BackupGuideViewController else{
                        self.toastMessage(title: "Save Failed".locStr)
                        return
                }
                vc.ifAccountInit = false
                self.navigationController?.present(vc, animated: true)
                
        }
        @IBAction func scanner(_ gesture: UITapGestureRecognizer) {
                let vc = instantiateViewController(vcID: "ScannerVC") as! ScannerViewController
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
        }
}
