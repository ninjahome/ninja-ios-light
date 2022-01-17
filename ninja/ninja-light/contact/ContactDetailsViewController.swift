//
//  NewContactViewController.swift
//  ninja-light
//
//  Created by hyperorchid on 2021/4/8.
//

import UIKit

class ContactDetailsViewController: UIViewController, UIGestureRecognizerDelegate {
        @IBOutlet weak var backContent: UIView!
        @IBOutlet weak var avator: AvatarButton!
        @IBOutlet weak var nickName: UILabel!
        @IBOutlet weak var uid: UILabel!
        @IBOutlet weak var deleteBtn: UIButton!
        @IBOutlet weak var moreBtn: UIButton!

        @IBOutlet weak var nickTextField: UITextField!
        @IBOutlet weak var memoTextView: UITextView!

        var itemUID:String?
        var itemData:ContactItem?
        var account: AccountItem?

        var _delegate: UIGestureRecognizerDelegate?

        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)

                self.navigationController?.setNavigationBarHidden(true, animated: true)

                if (self.navigationController?.viewControllers.count)! >= 1 {
                        _delegate = self.navigationController?.interactivePopGestureRecognizer?.delegate
                        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
                }
                self.account = AccountItem.GetAccount(itemUID!)
        }
    
        override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.interactivePopGestureRecognizer?.delegate = _delegate
        }
  
        override func viewDidLoad() {
                super.viewDidLoad()

                self.hideKeyboardWhenTappedAround()
                self.populateView()

                nickTextField.text = itemData?.alias
                memoTextView.text = itemData?.remark

                backContent.layer.contents = UIImage(named: "user_backg_img")?.cgImage

                setAvatar()

                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(notifiAction(notification:)),
                                                               
                                                       name: NotifyContactChanged,
                                                       object: nil)

        }
    
        deinit {
                NotificationCenter.default.removeObserver(self)
        }

        @objc func notifiAction(notification:NSNotification){
                if let data = notification.object as? ContactItem {
                        self.itemData = data
                        self.populateView()
                        self.setAvatar()
                }
        }
    
        private func setAvatar() {
                guard let uid = itemData?.uid else {
                        return
                }

                avator.type = AvatarButtonType.chatContact
                avator.avaInfo = AvatarInfo.init(id: uid, avaData: account?.Avatar)
        }
    
        @IBAction func backBtn(_ sender: UIButton) {
                let contact = ContactItem.init()
                contact.uid = itemData?.uid
                contact.alias = self.nickTextField.text
                contact.remark = self.memoTextView.text

                if let err = ContactItem.UpdateContact(contact) {
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                       object: contact, userInfo:nil)
                        self.toastMessage(title: err.localizedDescription)
                }

                self.navigationController?.popToRootViewController(animated: true)
        }
    
        @IBAction func moreBarItem(_ sender: UIButton) {
                if deleteBtn.isHidden {
                        deleteBtn.isHidden = false
                        moreBtn.setImage(UIImage(named: "x_icon"), for: .normal)
                } else {
                        deleteBtn.isHidden = true
                        moreBtn.setImage(UIImage(named: "more_icon"), for: .normal)
                }
        }
    
        @IBAction func deleteContact(_ sender: UIButton) {
                guard let uid = self.uid.text else{
                        return
                }

                guard let err = ContactItem.DelContact(uid) else{
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                        object: nil, userInfo:nil)
                        
                        self.closeWindow()
                        return
                }

                self.toastMessage(title: err.localizedDescription)
        }
    
        @IBAction func copyContactAddr(_ sender: UIButton) {
                UIPasteboard.general.string = itemData?.uid
                self.toastMessage(title: "Copy Success")
        }

        @IBAction func contactQRAlert(_ sender: UIButton) {
                if let uid = itemData?.uid {
                        ShowQRAlertView(data: uid)
                }
        }
    
        private func populateView() {
                if let newUid = self.itemUID {
                        if let obj = ContactItem.GetContact(newUid){
                                self.itemData = obj
                        }else{
                                self.uid.text = newUid
                        }
                }

                guard let data = self.itemData else {
                        return
                }
                self.uid.text = data.uid
                self.nickName.text = data.alias
        }

        private func closeWindow(){
                self.dismiss(animated: true)
                self.navigationController?.popViewController(animated: true)
        }

        @IBAction func StartChat(_ sender: UIButton) {
                guard self.uid.text != nil else{
                        return
                }
                let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                vc.peerUid = self.uid.text!
            
                self.navigationController?.pushViewController(vc, animated: true)
        }
    
}
