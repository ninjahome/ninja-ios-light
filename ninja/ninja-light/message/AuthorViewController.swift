//
//  AuthorViewController.swift
//  ninja-light
//
//  Created by wesley on 2021/4/11.
//

import UIKit

class AuthorViewController: UIViewController {

        @IBOutlet weak var tips: UILabel!
        @IBOutlet weak var password: UITextField!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.hideKeyboardWhenTappedAround()
                if #available(iOS 13.0, *) {
                        self.isModalInPresentation = true
                }
            
                if Wallet.shared.useFaceID {
                    biometryUsage { (success) in
                        if success, let pwd = KeychainWrapper.standard.string(forKey: "AUTHKey") {
                            self.unlock(auth: pwd)
                        } else {
                            return
                        }
                    }
                }
        }
        
        @IBAction func Auth(_ sender: Any) {
                guard let pwd = password.text else{
                        tips.text = "please input your password"
                        return
                }
            
                unlock(auth: pwd)
        }
    
        func unlock(auth pwd: String) {
            self.showIndicator(withTitle: "", and: "opening")
            
            DispatchQueue.global().async {
                    guard let err = Wallet.shared.Active(pwd) else{
                            DispatchQueue.main.async {
                                    self.hideIndicator()
                                    self.hideKeyboardWhenTappedAround()
                                    self.dismiss(animated: true)
                            }
                            return
                    }
                    DispatchQueue.main.async {
                            self.tips.text = err.localizedDescription
                            self.hideIndicator()
                            self.hideKeyboardWhenTappedAround()
                    }
            }
        }
        
}
