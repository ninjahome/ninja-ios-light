//
//  DestroyViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/24.
//

import UIKit

protocol SetupDestroyDelegate {
        func DestroyStatusResult(status : Bool)
}

class DestroyViewController: UIViewController {
        
        @IBOutlet weak var pwdField1: UITextField!
        @IBOutlet weak var pwdField2: UITextField!
        var statusResultDelegate:SetupDestroyDelegate?
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.hideKeyboardWhenTappedAround()
        }
        
        @IBAction func confirmDestroyBtn(_ sender: UIButton) {
                guard let pwd = pwdField1.text, pwd == pwdField2.text  else{
                        self.toastMessage(title: "Invaild password".locStr)
                        return
                }
                if Wallet.shared.openDestroy(auth: pwd) {
                        self.dismiss(animated: true){
                                guard let callback = self.statusResultDelegate else{
                                        return
                                }
                                callback.DestroyStatusResult(status: true)
                        }
                } else {
                        self.toastMessage(title: "Open destroy mode faild".locStr)
                }
                
        }
        
        
        @IBAction func dismissView(_ sender: UIButton) {
                self.dismiss(animated: true){
                        guard let callback = self.statusResultDelegate else{
                                return
                        }
                        callback.DestroyStatusResult(status: false)
                }
        }
}
