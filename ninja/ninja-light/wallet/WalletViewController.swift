//
//  WalletViewController.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit

class WalletViewController: UIViewController {
        @IBOutlet weak var nickName: UILabel!
//        @IBOutlet weak var avatarImg: UIImageView!
        @IBOutlet weak var address: UILabel!
        
        @IBOutlet weak var faceIDSwitch: UISwitch!
    
    @IBOutlet weak var avatar: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            address.text = Wallet.shared.Addr
            nickName.text = Wallet.shared.nickName
            faceIDSwitch.isOn = Wallet.shared.useFaceID
        }
    
        override func viewDidLoad() {
                super.viewDidLoad()
           
            let avaText = Wallet.GenAvatarText()
            avatar.setTitle(avaText, for: .normal)
            
            let hex = Wallet.GenAvatarColor()
            avatar.backgroundColor = UIColor.init(hex: hex)
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
    
        @IBAction func setUseFaceID(_ sender: UISwitch) {
            if sender.isOn {
                biometryUsage { (usageRes) in
                    if usageRes {
                        self.showPwdInput(title: "请输入解锁密码", placeHolder: "请输入密码", securityShow: true) { (password, isOK) in
                            guard let pwd = password, isOK else{
                                    return
                            }
                            
                            if !Wallet.shared.openFaceID(auth: pwd) {
                                return
                            }
                            
                            self.dismiss(animated: true)
                        }
                    } else {
                        self.faceIDSwitch.isOn = !sender.isOn
                    }
                }
            } else {
                if let err = Wallet.shared.UpdateUseFaceID(by: sender.isOn) {
                    faceIDSwitch.isOn = !sender.isOn
                    self.toastMessage(title: err.localizedDescription)
                }
            }
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
