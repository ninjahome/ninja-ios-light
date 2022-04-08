//
//  NewWalletViewController.swift
//  immeta
//
//  Created by wesley on 2021/4/5.
//

import UIKit

class NewWalletViewController: UIViewController {
        
        @IBOutlet weak var password2: UITextField!
        @IBOutlet weak var password1: UITextField!
        
        @IBOutlet weak var importtext: UILabel!
        @IBOutlet weak var importbtn: UIButton!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.hideKeyboardWhenTappedAround()
                
                if Wallet.shared.Addr != nil {
                        importtext.isHidden = true
                        importbtn.isHidden = true
                }
        }
        
        @IBAction func CreateWallet(_ sender: UIButton) {
                guard let password = self.password1.text,password != ""else {
                        self.toastMessage(title: "Password can't be empty".locStr)
                        return
                }
                if password != self.password2.text{
                        self.toastMessage(title: "Two passwords are not same".locStr)
                        return
                }
                
                if Wallet.shared.Addr != nil {
                        ServiceDelegate.cleanAllMemoryCache()
                }
                
                
                self.showIndicator(withTitle: "", and: "Creating".locStr)
                ServiceDelegate.workQueue.async {
                        
                        do {
                                try Wallet.shared.New(password)
                        } catch let err as NSError{
                                self.hideIndicator()
                                self.toastMessage(title: err.localizedDescription)
                                return
                        }
                        ServiceDelegate.InitService()
                        if isFirstUser() {
                                setFirstUser()
                        }
                        DispatchQueue.main.async {
                                self.hideIndicator()
                                self.performSegue(withIdentifier: "CreateNewAccountSeg", sender: self)
                        }
                }
        }
        
        @IBAction func scanner(_ sender: UIButton) {
                let vc = instantiateViewController(vcID: "ScannerVC") as! ScannerViewController
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
        }
}

extension NewWalletViewController: ScannerViewControllerDelegate {
        
        func codeDetected(code: String) {
                
                print("------>>>New wallet code\(code)")
                guard let addr = Wallet.shared.serializeWalletJson(cipher: code) else {
                        self.toastMessage(title: "Invaild ninja wallet address".locStr)
                        return
                }
                
                self.showPwdInput(title: "Import account".locStr, placeHolder: "Please input password".locStr, securityShow: true) { (auth, isOK) in
                        guard let pwd = auth, isOK else{
                                return
                        }
                        
                        ServiceDelegate.ImportNewAccount(wJson: code, addr: addr, pwd: pwd, parent: self, callback: afterWallet)
                }
        }
}
