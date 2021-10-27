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
    @IBOutlet weak var destroySwitch: UISwitch!
    
    @IBOutlet weak var avatar: AvatarButton!
    @IBOutlet weak var backGroundView: UIView!
    
    @IBOutlet weak var agentBtn: AgentButton!
    @IBOutlet weak var agentLabel: UILabel!
    @IBOutlet weak var agentTime: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        address.text = Wallet.shared.Addr
        nickName.text = Wallet.shared.nickName
        faceIDSwitch.isOn = Wallet.shared.useFaceID
        destroySwitch.isOn = Wallet.shared.useDestroy
        
        avatar.type = AvatarButtonType.wallet
        avatar.avaInfo = nil
        
        DispatchQueue.global().async {
            let status = AgentService.shared.getAgentStatus()
            DispatchQueue.main.async {
                self.agentBtn.currentStatus = status
                self.agentLabel.text = status.handleText[1]
                
                switch status {
                case .activated:
                    self.agentTime.text = "\(AgentService.shared.expireDate)到期"
                case .almostExpire:
                    self.agentTime.text = String(format: "%4d 天", AgentService.shared.expireDays)
                case .initial:
                    self.agentTime.text = "账号激活后才能正常使用"
                    break
                }
                
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backGroundView.layer.contents = UIImage(named: "user_backg_img")?.cgImage
        
        DispatchQueue.global().async {
            let status = AgentService.shared.getAgentStatus()
            DispatchQueue.main.async {
                self.agentBtn.currentStatus = status
                self.agentLabel.text = status.handleText[1]
                
                switch status {
                case .activated:
                    self.agentTime.text = "\(AgentService.shared.expireDate)到期"
                case .almostExpire:
                    self.agentTime.text = String(format: "%4d 天", AgentService.shared.expireDays)
                case .initial:
                    self.agentTime.text = "账号激活后才能正常使用"
                    break
                }
                
            }
        }
        
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
    
    @IBAction func setDestroy(_ sender: UISwitch) {
        if sender.isOn {
            self.performSegue(withIdentifier: "ShowDestroySEG", sender: self)
        } else {
            if let err = Wallet.shared.UpdateUseDestroy(by: false) {
                destroySwitch.isOn = false
                self.toastMessage(title: err.localizedDescription)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditNicknameSEG", let vc = segue.destination as? NickEditViewController {
                vc.nick = nickName.text
            vc.returnHost = {[weak self] res in
                self?.nickName.text = res
                self?.avatar.avaInfo = nil
            }
        }
    }

}
