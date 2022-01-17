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
        
        var uid: String?
        var account: AccountItem?
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                account = AccountItem.shared.getLatestAccount(addr: uid!)
        }
    
        override func viewDidLoad() {
                super.viewDidLoad()
                uidText.text = uid
                avatar.type = .chatContact
                avatar.avaInfo = AvatarInfo(id: uid!, avaData: self.account?.Avatar)
                nickName.text = account?.NickName
                backContent.layer.contents = UIImage(named: "user_backg_img")?.cgImage
        }
    
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    
        @IBAction func backBtn(_ sender: UIButton) {
                self.navigationController?.popViewController(animated: true)
        }
    
        @IBAction func saveToContact(_ sender: Any) {
        
                let contact = ContactItem.init()
                contact.uid = self.uid
        //                contact.nickName = self.nickName.text
        //                contact.remark = remarks.text
        //                contact.avatar = self.avatar.image?.pngData()//TODO::Load avatar from netework
                _ = AccountItem.UpdateOrAddAccount(account!)
                guard let err = ContactItem.UpdateContact(contact) else{
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                object: nil, userInfo:nil)
                        return
                }

                self.toastMessage(title: err.localizedDescription)
        }
        
        @IBAction func sendMsg(_ sender: UIButton) {
                guard let id = self.uid else {
                        return
                }
                let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                vc.peerUid = id
                self.navigationController?.pushViewController(vc, animated: true)
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "SaveNewContactSeg" {
                        let contact = ContactItem.init()
                        contact.uid = self.uid

                        let vc = segue.destination as! ContactDetailsViewController
                        vc.itemUID = self.uid
                        vc.itemData = contact
                }
        }
}
