//
//  ConfirmTransferViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/27.
//

import UIKit

class ConfirmTransferViewController: UIViewController {
        
        @IBOutlet weak var transferAddr: UILabel!
        @IBOutlet weak var expire: UILabel!
        @IBOutlet weak var inputTransferDays: UITextField!
        @IBOutlet weak var confirmBtn: UIButton!
        
        var transAddress: String?
        
        override func viewDidLoad() {
                super.viewDidLoad()
                transferAddr.text = transAddress
                let expireDays = Wallet.shared.getBalance()
                expire.text = String(format: "剩余激活天数 %.2f 天", expireDays)
                self.hideKeyboardWhenTappedAround()
        }
        
        @IBAction func transferAll(_ sender: UIButton) {
                
                let expireDays = Wallet.shared.getBalance()
                inputTransferDays.text = String(expireDays )
        }
        
        @IBAction func confirmTransfer(_ sender: UIButton) {
                guard let days = inputTransferDays.text, let dayInt = Int(days) else {
                        return
                }
                
                guard let addr = transAddress else {
                        return
                }
                
                self.showIndicator(withTitle: "", and: "transfering")
                ServiceDelegate.workQueue.async {
                        if let err = ServiceDelegate.transferLicense(to: addr, days: dayInt) {
                                self.toastMessage(title: "faild[\(err.localizedDescription)]")
                                return
                        }
                        DispatchQueue.main.async {
                                self.navigationController?.popToRootViewController(animated: true)
                        }}
                
        }
        
        @IBAction func returnItem(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }
        
}
