//
//  NickEditViewController.swift
//  ninja-light
//
//  Created by akatuki on 2021/5/17.
//

import UIKit

typealias editHost = (String) -> Void

class NickEditViewController: UIViewController {
    var nick: String?
    var returnHost: editHost!

    @IBOutlet weak var nickText: UITextField!
    @IBOutlet weak var avatar: AvatarButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if nick != nil {
            nickText.text = nick
        }
        
        avatar.type = AvatarButtonType.wallet
        avatar.avaInfo = nil
//        let avaText = Wallet.GenAvatarText()
//        avatar.setTitle(avaText, for: .normal)
//
//        let hex = Wallet.GenAvatarColor()
//        avatar.backgroundColor = UIColor.init(hex: hex)
        
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
