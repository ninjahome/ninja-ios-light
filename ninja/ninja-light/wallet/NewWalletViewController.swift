//
//  NewWalletViewController.swift
//  ninja-light
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
                        self.toastMessage(title: "Password can't be empty")
                        return
                }
                if password != self.password2.text{
                        self.toastMessage(title: "2 passwords are not same")
                        return
                }
                
                if Wallet.shared.Addr != nil {
                        ServiceDelegate.cleanAllData()
                }
                
                
                self.showIndicator(withTitle: "", and: "creating")
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
                        self.toastMessage(title: "invaild ninja wallet address")
                        return
                }
                
                self.showPwdInput(title: "请输入密码导入账号", placeHolder: "请输入密码", securityShow: true) { (auth, isOK) in
                        guard let pwd = auth, isOK else{
                                return
                        }
                        
                        ServiceDelegate.ImportNewAccount(wJson: code, addr: addr, pwd: pwd, parent: self, callback: afterWallet)
                }
        }
}
