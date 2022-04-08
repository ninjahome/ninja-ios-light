//
//  AuthorViewController.swift
//  immeta
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
        
        var delegate:WalletDelegate?
        
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
        
        override func viewWillAppear(_ animated: Bool) {
                if Wallet.shared.useGesture {
                        let vc = GestureViewController()
                        vc.type = .verify
                        vc.modalPresentationStyle = .overFullScreen
                        vc.delegate = self
                        self.present(vc, animated: true, completion: nil)
                }
        }
        
        @IBAction func Auth(_ sender: Any) {
                guard let pwd = password.text else {
                        tips.text = "input password please".locStr
                        return
                }
                
                if Wallet.shared.useDestroy,
                   pwd == DeriveDestroyKey() {
                        destroy(auth: pwd)
                        return
                }
                
                unlock(auth: pwd)
        }
        
        //TODO:: to be tested
        func destroy(auth: String) {
                self.showIndicator(withTitle: "", and: "Opening".locStr)
                
                ServiceDelegate.workQueue.async {
                        do {
                                try Wallet.shared.New(auth)
                                _ = Wallet.shared.Active(auth)
                                ServiceDelegate.InitService()
                                DispatchQueue.main.async {
                                        self.dismiss(animated: true){
                                                self.delegate?.OpenSuccess()
                                        }
                                }
                                
                        } catch _ {
                                self.hideIndicator()
                                self.hideKeyboardWhenTappedAround()
                        }
                }
        }
        
        func unlock(auth pwd: String) {
                self.showIndicator(withTitle: "", and: "Opening".locStr)
                
                ServiceDelegate.workQueue.async {
                        if let err = Wallet.shared.Active(pwd) {
                                self.hideIndicator()
                                self.hideKeyboardWhenTappedAround()
                                self.ShowTips(msg: "Active Failed:\(err.localizedDescription)")
                                return
                        }
                        
                        DispatchQueue.main.async {
                                self.hideIndicator()
                                self.dismiss(animated: true){
                                        self.delegate?.OpenSuccess()
                                }
                        }
                }
        }
        
}

extension AuthorViewController: GestureVerified {
        func verified(success: Bool) {
                if success, let pwd = DeriveAesKey() {
                        self.unlock(auth: pwd)
                }
        }
}
