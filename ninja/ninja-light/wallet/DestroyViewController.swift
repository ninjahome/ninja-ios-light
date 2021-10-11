//
//  DestroyViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/24.
//

import UIKit

class DestroyViewController: UIViewController {
    
    @IBOutlet weak var pwdField1: UITextField!
    @IBOutlet weak var pwdField2: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
    }
    
    @IBAction func confirmDestroyBtn(_ sender: UIButton) {
        if let pwd = pwdField1.text, pwd == pwdField2.text {
            if Wallet.shared.openDestroy(auth: pwd) {
                self.dismiss(animated: true, completion: nil)
            } else {
                self.toastMessage(title: "Open destroy mode faild")
            }
        } else {
            self.toastMessage(title: "Invaild password")
        }
    }
    
    
    @IBAction func dismissView(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
