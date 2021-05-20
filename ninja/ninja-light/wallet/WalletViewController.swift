//
//  WalletViewController.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit

class WalletViewController: UIViewController {
        @IBOutlet weak var nickName: UILabel!
        @IBOutlet weak var avatarImg: UIImageView!
        @IBOutlet weak var address: UILabel!
        
        override func viewDidLoad() {
                super.viewDidLoad()
    
                address.text = Wallet.shared.Addr
                nickName.text = Wallet.shared.nickName
            
        }
    
        @IBAction func QRCodeShow(_ sender: Any) {
                guard let addr = self.address.text else {
                        return
                }
                self.ShowQRAlertView(data: addr)
        }
        
        @IBAction func Copy(_ sender: UIButton) {
                UIPasteboard.general.string = Wallet.shared.Addr
                self.toastMessage(title: "Copy Success")
        }
        
        @IBAction func ChangeNickName(_ sender: UIButton) {
//            self.performSegue(withIdentifier: "EditNicknameSEG", sender: self)
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "EditNicknameSEG", let vc = segue.destination as? NickEditViewController {
                    vc.nick = nickName.text
                vc.returnHost = {[weak self] res in
                    self?.nickName.text = res
                }
            }
        }
        
}
