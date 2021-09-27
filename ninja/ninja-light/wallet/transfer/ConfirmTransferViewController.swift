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
    var expireDays: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        transferAddr.text = transAddress
        expireDays = AgentService.shared.expireDays
        expire.text = "剩余激活天数\(expireDays ?? 0)天"
        
        self.hideKeyboardWhenTappedAround()
    }
    
    @IBAction func transferAll(_ sender: UIButton) {
        inputTransferDays.text = String(expireDays ??  0)
    }
    
    @IBAction func confirmTransfer(_ sender: UIButton) {
        guard let days = inputTransferDays.text, let dayInt = Int(days) else {
            return
        }
        
        guard let addr = transAddress else {
            return
        }
        
        if AgentService.shared.transferLicense(to: addr, days: dayInt) {
            
            self.toastMessage(title: "success")
            self.navigationController?.popToRootViewController(animated: true)
        } else {
            
            self.toastMessage(title: "faild")
        }
        
    }
    
    @IBAction func returnItem(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
