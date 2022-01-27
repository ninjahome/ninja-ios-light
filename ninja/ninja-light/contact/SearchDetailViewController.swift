//
//  SearchDetailViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/7/8.
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
        
        var uid: String?
        var account: AccountItem?
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                self.navigationController?.setNavigationBarHidden(true, animated: true)
        }
    
        override func viewDidLoad() {
                super.viewDidLoad()
                uidText.text = uid
                account = AccountItem.getLatestAccount(addr: uid!)
                _ = AccountItem.UpdateOrAddAccount(account!)
                avatar.type = .chatContact
                avatar.avaInfo = AvatarInfo(id: uid!, avaData: self.account?.Avatar)
                nickName.text = account?.NickName
                backContent.layer.contents = UIImage(named: "user_backg_img")?.cgImage
                
                self.hideKeyboardWhenTappedAround()
                vipFlagImgView.isHidden = Wallet.shared.isStillVip()
        }
    
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    
        @IBAction func backBtn(_ sender: UIButton) {
                self.navigationController?.popViewController(animated: true)
        }
        
        @IBAction func saveToContact(_ sender: Any) {
                
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                let contact = ContactItem.init()
                contact.uid = self.uid
                contact.remark = remark.text
                contact.alias = alias.text
                _ = AccountItem.UpdateOrAddAccount(account!)
                _ = ContactItem.AddNewContact(contact)
                startChat()
        }
        
        @IBAction func sendMsg(_ sender: UIButton) {
                startChat()
        }
        
        func startChat() {
                guard let id = self.uid else {
                        return
                }
                let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                vc.peerUid = id
                self.navigationController?.pushViewController(vc, animated: true)
        }
        
//        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//                if segue.identifier == "SaveNewContactSeg" {
//                        let contact = ContactItem.init()
//                        contact.uid = self.uid
//
//                        let vc = segue.destination as! ContactAliasViewController
//                        vc.itemUID = self.uid
//                        vc.itemData = contact
//                }
//        }
}
