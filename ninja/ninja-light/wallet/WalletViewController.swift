//
//  WalletViewController.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit

class WalletViewController: UITableViewController {
        @IBOutlet weak var address: UILabel!
    
        @IBOutlet weak var vipBackground: UIView!
        @IBOutlet weak var faceIDSwitch: UISwitch!
        @IBOutlet weak var destroySwitch: UISwitch!

        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var backGroundView: UIView!

        @IBOutlet weak var agentBtn: AgentButton!
        @IBOutlet weak var agentTime: UILabel!

        @IBOutlet weak var appVersion: UILabel!

        @IBOutlet weak var vipFlag: UIImageView!
        @IBOutlet weak var vipIcon: UIImageView!
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                
                address.text = Wallet.shared.Addr
                faceIDSwitch.isOn = Wallet.shared.useFaceID
                destroySwitch.isOn = Wallet.shared.useDestroy
                
                avatar.type = AvatarButtonType.wallet
                avatar.avaInfo = nil
                
                DispatchQueue.global().async {
                        let status = AgentService.shared.getAgentStatus()
                        DispatchQueue.main.async {
                                self.agentBtn.currentStatus = status
        //                        self.agentLabel.text = status.handleText[1]
                                switch status {
                                case .activated:
                                        self.agentTime.text = "\(AgentService.shared.expireDate)到期"
                                        self.vipBackground.layer.contents = UIImage(named: "VIP_BGC")?.cgImage
                                        self.agentBtn.setImage(nil, for: .normal)
                                        self.vipFlag(show: true)
                                case .almostExpire:
                                        self.agentTime.text = String(format: "%4d 天", AgentService.shared.expireDays)
                                        self.vipBackground.layer.contents = UIImage(named: "VIP_BGC")?.cgImage
                                
                                        self.agentBtn.setImage(UIImage(named: "red"), for: .normal)
                                        self.vipFlag(show: true)
                                case .initial:
                                        self.agentTime.text = "普通用户仅支持文本聊天"
                                        self.vipBackground.layer.contents = UIImage(named: "nor_bgc")?.cgImage
                                        self.agentBtn.setImage(nil, for: .normal)
                                        self.vipFlag(show: false)
                                    break
                                }
                        }
                }
        }
    
        override func viewDidLoad() {
                super.viewDidLoad()
                appVersion.text = getAppVersion()
                backGroundView.layer.contents = UIImage(named: "user_backg_img")?.cgImage

                DispatchQueue.global().async {
                        let status = AgentService.shared.getAgentStatus()
                        DispatchQueue.main.async {
                                self.agentBtn.currentStatus = status
                                //                self.agentLabel.text = status.handleText[1]

                                switch status {
                                case .activated:
                                        self.agentTime.text = "\(AgentService.shared.expireDate)到期"
                                        self.vipFlag(show: true)
                                case .almostExpire:
                                        self.agentTime.text = String(format: "%4d 天", AgentService.shared.expireDays)
                                        self.vipFlag(show: true)
                                case .initial:
                                        self.agentTime.text = "普通用户仅支持文本聊天"
                                        self.vipFlag(show: false)
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
    
    
    
        @IBAction func clearChatHistory(_ sender: UIButton) {
                let alertActionController = UIAlertController.init(title: "", message: "将删除所有个人和群的聊天记录", preferredStyle: .actionSheet)
                alertActionController.modalPresentationStyle = .popover

                let deleteAction = UIAlertAction(title: "清空聊天记录", style: .destructive) { action in
                        MessageItem.removeAllRead()
                }
                let cancleAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)

                alertActionController.addAction(deleteAction)
                alertActionController.addAction(cancleAction)

                self.present(alertActionController, animated: true, completion: nil)
        }
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "EditNicknameSEG", let vc = segue.destination as? NickEditViewController {
                        vc.returnHost = {[weak self] res in
                                self?.avatar.avaInfo = nil
                        }
                }
        }
        
        func vipFlag(show: Bool) {
                if show {
                        self.vipIcon.isHidden = false
                        self.vipFlag.isHidden = false
                } else  {
                        self.vipFlag.isHidden = true
                        self.vipIcon.isHidden = true
                }
                
        }

}
