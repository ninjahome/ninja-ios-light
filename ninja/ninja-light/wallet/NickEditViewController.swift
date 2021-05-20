//
//  NickEditViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/5/17.
//

import UIKit

typealias editHost = (String) -> Void

class NickEditViewController: UIViewController {
    var nick: String?
    var returnHost: editHost!

    @IBOutlet weak var nickText: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if nick != nil {
            nickText.text = nick
        }
        
        self.hideKeyboardWhenTappedAround()
    }
    
    @IBAction func saveNick(_ sender: UIButton) {
        guard let nickStr = nickText.text else {
            return
        }
        guard let error = Wallet.shared.UpdateNick(by: nickStr) else {
            self.returnHost(nickStr)
            self.closeWindow()
            return
        }
        
        self.toastMessage(title: error.localizedDescription)
    }
    
    private func closeWindow() {
            self.dismiss(animated: true)
            self.navigationController?.popViewController(animated: true)
    }

    
}
