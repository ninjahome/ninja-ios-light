//
//  WalletViewController.swift
//  immeta
//
//  Created by wesley on 2021/3/30.
//

import UIKit

class WalletViewController: UITableViewController {
        @IBOutlet weak var address: UILabel!
    
        @IBOutlet weak var vipBackground: UIView!
//        @IBOutlet weak var faceIDSwitch: UISwitch!
        @IBOutlet weak var destroySwitch: UISwitch!
        @IBOutlet weak var gestureSwitch: UISwitch!
        @IBOutlet weak var msgBlockSwitch: UISwitch!
        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var backGroundView: UIView!

        @IBOutlet weak var agentBtn: AgentButton!
        @IBOutlet weak var agentTime: UILabel!
        @IBOutlet weak var pushStatus: UISwitch!

        @IBOutlet weak var appVersion: UILabel!

        @IBOutlet weak var nickName: UILabel!
        
        @IBOutlet weak var vipFlag: UIImageView!
        @IBOutlet weak var vipIcon: UIImageView!

        @IBOutlet weak var readBurnDays: UILabel!
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
//                balanceStatusView()
                updateWholeView()
                setupNotiStatus()
                if let days = ConfigItem.shared.keepDays {
                        readBurnDays.text = "\(days) \("Days".locStr)"
                }
                
        }
        private func setupNotiStatus(){
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                        DispatchQueue.main.async {
                                self.pushStatus.isOn = settings.authorizationStatus == .authorized
                        }
                }
        }
        override func viewDidLoad() {
                super.viewDidLoad()
                appVersion.text = getAppVersion()
                nickName.text = Wallet.shared.nickName
//                backGroundView.layer.contents = UIImage(named: "user_backg_img")?.cgImage
                
                self.refreshControl = UIRefreshControl()
                refreshControl?.addTarget(self, action: #selector(self.reloadWallet(_:)), for: .valueChanged)
                self.view.addSubview(refreshControl!)
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(licenseUpdate(notification:)),
                                                       name: NotifyLicenseChanged,
                                                       object: nil)
                DispatchQueue.global().async {
                        Wallet.shared.getLatestWallt()
                        self.updateWholeView()
                }
        }
        
        @objc func licenseUpdate(notification: NSNotification) {
                self.updateWholeView()
        }
        
        @objc func reloadWallet(_ sender: Any?) {
//                DispatchQueue.global().async {
                        Wallet.shared.getWalletFromETH()
//                        Wallet.shared.getLatestWallt()
                        self.updateWholeView()
//                }
                self.refreshControl?.endRefreshing()
        }
        
        private func balanceStatusView() {
                let status = ServiceDelegate.getAgentStatus()
                        self.agentBtn.currentStatus = status
        }
        
        private func updateWholeView() {
                
                DispatchQueue.main.async {
                        self.address.text = Wallet.shared.Addr
//                        self.faceIDSwitch.isOn = Wallet.shared.useFaceID
                        self.destroySwitch.isOn = Wallet.shared.useDestroy
                        self.gestureSwitch.isOn = Wallet.shared.useGesture
                        self.nickName.text = Wallet.shared.nickName
                        self.avatar.setupSelf()
                     
                        let status = ServiceDelegate.getAgentStatus()
                        self.agentBtn.currentStatus = status
                        let balance = Wallet.shared.getBalance()
//                        let expire = formatTimeStampOnlyDate(by: Wallet.shared.liceneseExpireTime)
                        switch status {
                        case .activated:
                                self.agentTime.text = String(format: "%.2f", balance)
//                                self.agentTime.font = UIFont(name: "", size: 12)
                                self.agentTime.textColor = UIColor(hex: "FFE3BB")
//                                self.vipBackground.layer.contents = UIImage(named: "VIP_BGC")?.cgImage
                                self.vipBackground.backgroundColor = .black
                                self.agentBtn.setImage(nil, for: .normal)
                                self.vipFlag(show: true)
                        case .almostExpire:
                                self.agentTime.text = String(format: "%.2f", balance)
                                self.agentTime.textColor = UIColor(hex: "FFE3BB")
//                                self.agentTime.font = UIFont(name: "", size: 12)
//                                self.vipBackground.layer.contents = UIImage(named: "VIP_BGC")?.cgImage
                                self.vipBackground.backgroundColor = .black
                                self.agentBtn.setImage(UIImage(named: "red"), for: .normal)
                                self.vipFlag(show: true)
                        case .initial:
                                self.agentTime.text = "Plain text only for free user".locStr
//                                self.vipBackground.layer.contents = UIImage(named: "nor_bgc")?.cgImage
                                self.vipBackground.backgroundColor = UIColor(hex: "EFF1F2")
                                self.agentBtn.setImage(nil, for: .normal)
                                self.vipFlag(show: false)
                            break
                        }
                }
        }

        
//        @IBAction func setUseFaceID(_ sender: UISwitch) {
//                if sender.isOn {
//                        biometryUsage { (usageRes) in
//                                if usageRes {
//                                        self.showPwdInput(title: "password", placeHolder: "password", securityShow: true) { (password, isOK) in
//                                                guard let pwd = password, isOK else{
//                                                        return
//                                                }
//
//                                                if !Wallet.shared.openFaceID(auth: pwd) {
//                                                        return
//                                                }
//
//                                                self.dismiss(animated: true)
//                                        }
//                                } else {
//                                        self.faceIDSwitch.isOn = !sender.isOn
//                                }
//                        }
//                } else {
//                        if let err = Wallet.shared.UpdateUseFaceID(by: sender.isOn) {
//                                faceIDSwitch.isOn = !sender.isOn
//                                self.toastMessage(title: err.localizedDescription)
//                        }
//                }
//        }
    
        @IBAction func setDestroy(_ sender: UISwitch) {
                if sender.isOn {
                        self.performSegue(withIdentifier: "ShowDestroySEG", sender: self)
                } else {
                        if let err = Wallet.shared.UpdateUseDestroy(by: false) {
                                destroySwitch.isOn = true
                                self.toastMessage(title: "Faild".locStr+"\(err.localizedDescription ?? "")")
                        }
                }
        }
        
        @IBAction func switchPushStatus(_ sender: UISwitch) {
                if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
                setupNotiStatus()
        }
        
        @IBAction func switchMsgBlock(_ sender: UISwitch) {
                if let err = ConfigItem.setupMsgBlock(sender.isOn) {
                        self.toastMessage(title: "save block message failed".locStr)
                        print("------->>>update keep days faild: \(err.localizedDescription ?? "")")
                }
        }
        
        @IBAction func setGesture(_ sender: UISwitch) {
                if sender.isOn {
                        self.showPwdInput(title: "input password please".locStr, placeHolder: "password".locStr, securityShow: true) { (password, isOK) in
                                guard let pwd = password, isOK else {
                                        return
                                }
                                
                                if !Wallet.shared.openGesture(auth: pwd) {
                                        return
                                }
                                
                                let vc = GestureViewController()
                                vc.type = .set
                                self.navigationController?.pushViewController(vc, animated: true)

                        }
                        
                } else {
                        if let err = Wallet.shared.UpdateUseGesture(by: false) {
                                sender.isOn = true
                                self.toastMessage(title: "Faild".locStr+"\(err.localizedDescription ?? "")")
                        }
                }
        }
    
        @IBAction func clearChatHistory(_ sender: UIButton) {
                let alertActionController = UIAlertController.init(title: "", message: "message will be deleted".locStr, preferredStyle: .actionSheet)
                alertActionController.modalPresentationStyle = .popover

                let deleteAction = UIAlertAction(title: "delete messages".locStr, style: .destructive) { action in
                        self.showIndicator(withTitle: "", and: "deleting message caches".locStr)
                        ServiceDelegate.workQueue.async {
                                MessageItem.removeAllRead()
                                ChatItem.clearAllUnreadFlag()
                                self.hideIndicator()
                        }
                }
                let cancleAction = UIAlertAction(title: "Cancel".locStr, style: .cancel, handler: nil)

                alertActionController.addAction(deleteAction)
                alertActionController.addAction(cancleAction)

                self.present(alertActionController, animated: true, completion: nil)
        }
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "EditNicknameSEG", let vc = segue.destination as? NickEditViewController {
                        vc.nick = Wallet.shared.nickName
                        vc.returnHost = {[weak self] res in
                                self?.avatar.peerID = ""//TODO::
                        }
                }else if "ShowDestroySEG" == segue.identifier, let vc = segue.destination as? DestroyViewController{
                        vc.statusResultDelegate = self
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

extension WalletViewController:SetupDestroyDelegate{
        func DestroyStatusResult(status : Bool){
                destroySwitch.isOn = status
        }
}
