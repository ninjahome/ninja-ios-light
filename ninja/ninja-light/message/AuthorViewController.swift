//
//  AuthorViewController.swift
//  ninja-light
//
//  Created by wesley on 2021/4/11.
//

import UIKit

protocol WalletDelegate{
    func OpenSuccess()
}

class AuthorViewController: UIViewController {

        @IBOutlet weak var tips: UILabel!
        @IBOutlet weak var password: UITextField!
        
        @IBOutlet weak var avatar: UIImageView!
        @IBOutlet weak var nick: UILabel!
        
        var walletDelegate: WalletDelegate?
    
        override func viewDidLoad() {
                super.viewDidLoad()
                if let avaData = Wallet.shared.avatarData {
                        avatar.image = UIImage(data: avaData)
                        avatar.layer.cornerRadius = 45
                        avatar.layer.masksToBounds = true
                }

                nick.text = Wallet.shared.nickName
                
                self.hideKeyboardWhenTappedAround()
                if #available(iOS 13.0, *) {
                        self.isModalInPresentation = true
                }
                
                if Wallet.shared.useFaceID {
                        biometryUsage { (success) in
                                if success, let pwd = DeriveAesKey() {
                                        self.unlock(auth: pwd)
                                } else {
                                        return
                                }
                        }
                }
        }
    
        @IBAction func Auth(_ sender: Any) {
                guard let pwd = password.text else {
                        tips.text = "please input your password"
                        return
                }

                if Wallet.shared.useDestroy,
                   pwd == DeriveDestroyKey() {
                        destroy(auth: pwd)
                        return
                }

                unlock(auth: pwd)
        }
    
        func destroy(auth: String) {
                self.showIndicator(withTitle: "", and: "opening")

                DispatchQueue.global().async {
                        do {
                                try Wallet.shared.New(auth)
                                ServiceDelegate.InitService()
                                _ = Wallet.shared.Active(auth)

                                ChatItem.ReloadChatRoom()
                                ContactItem.LocalSavedContact()

                                DispatchQueue.main.async {
                                        self.dismiss(animated: true, completion: nil)
                                }

                        } catch let err {
                                DispatchQueue.main.async {
                                        self.hideIndicator()
                                        self.tips.text = err.localizedDescription
                                        self.hideKeyboardWhenTappedAround()
                                }
                        }
                }
        }

        func unlock(auth pwd: String) {
                self.showIndicator(withTitle: "", and: "opening")

                DispatchQueue.global().async {
                        guard let err = Wallet.shared.Active(pwd) else {
                                DispatchQueue.main.async {
                                        self.hideIndicator()
                                        self.hideKeyboardWhenTappedAround()
                                        Wallet.shared.accountNonce()
                                        self.dismiss(animated: true) {
                                                self.walletDelegate?.OpenSuccess()
                                        }
                                }
                                MessageItem.deleteMsgOneWeek()
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
