//
//  SearchDetailViewController.swift
//  immeta
//
//  Created by ribencong on 2021/7/8.
//

import UIKit

class SearchDetailViewController: UIViewController {
        @IBOutlet weak var backContent: UIView!
        
        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var uidText: UILabel!
        @IBOutlet weak var nickName: UILabel!
        @IBOutlet weak var vipFlagImgView: UIImageView!
        @IBOutlet weak var alias: UITextField!
        @IBOutlet weak var remark: UITextView!
        
        var uid: String = ""
        private var accountData: AccountItem?
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
                uidText.text = uid
                self.hideKeyboardWhenTappedAround()
                self.showIndicator(withTitle: "loading", and: "account data on chain")
                ServiceDelegate.workQueue.async {
                        guard let data = AccountItem.extraLoad(pid: self.uid, forceUpdate: true) else{
                                self.hideIndicator()
                                return
                        }
                        self.accountData = data
                        DispatchQueue.main.async {
                                self.hideIndicator()
                                self.populateView()
                                
                                NotificationCenter.default.post(name:NotifyContactChanged, object: self.uid)
                        }
                }
        }
        
        private func populateView(){
                avatar.setup(id: uid, avaData: accountData?.Avatar, showDetails: false)
                nickName.text = accountData?.NickName//TODO::
//                backContent.layer.contents = UIImage(named: "user_backg_img")?.cgImage
                vipFlagImgView.isHidden = Wallet.shared.isStillVip()
        }
        
        override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
                self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
        
        @IBAction func backBtn(_ sender: UIButton) {
                self.navigationController?.popViewController(animated: true)
        }
        
        @IBAction func copyAddr(_ sender: UIButton) {
                UIPasteboard.general.string = uid
                self.toastMessage(title: "Copy Success".locStr)
        }
        
        @IBAction func showQr(_ sender: UIButton) {
                ShowQRAlertView(data: uid)
        }
        
        @IBAction func saveToContact(_ sender: Any) {
                
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                
                let contact = ContactItem.init(pid: self.uid, alias: self.alias.text, remark: self.remark.text)
                self.showIndicator(withTitle: "waiting", and: "save to Chain")
                ServiceDelegate.workQueue.async {
                        let cc = CombineConntact()
                        cc.peerID = self.uid
                        cc.account = self.accountData
                        cc.contact = contact
                        let err = cc.SyncNewItemToChain()
                        CDManager.shared.saveContext()
                        DispatchQueue.main.async {
                                self.hideIndicator()
                                if let e = err{
                                        self.ShowTips(msg: e.localizedDescription)
                                        return
                                }
                                
                                NotificationCenter.default.post(name:NotifyContactChanged, object: self.uid)
                                self.startChat()
                        }
                }
        }
        
        @IBAction func sendMsg(_ sender: UIButton) {
                startChat()
        }
        
        func startChat() {
                let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                vc.peerUid = self.uid
                self.navigationController?.pushViewController(vc, animated: true)
        }
}
