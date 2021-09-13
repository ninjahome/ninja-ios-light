//
//  NewContactViewController.swift
//  ninja-light
//
//  Created by hyperorchid on 2021/4/8.
//

import UIKit

class ContactDetailsViewController: UIViewController {
        
//        @IBOutlet weak var uid: UITextView!
//        @IBOutlet weak var remarks: UITextView!
//        @IBOutlet weak var nickName: UITextField!
//        @IBOutlet weak var avatar: UIImageView!
//        @IBOutlet weak var chatBtn: UIButton!
//        @IBOutlet weak var delBarBtn: UIBarButtonItem!
        
    @IBOutlet weak var backContent: UIView!
    @IBOutlet weak var avator: AvatarButton!
    @IBOutlet weak var nickName: UILabel!
    @IBOutlet weak var uid: UILabel!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var moreBtn: UIButton!
    @IBOutlet weak var memo: UILabel!
    
    var itemUID:String?
    var itemData:ContactItem?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
 
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.hideKeyboardWhenTappedAround()
        self.populateView()
        
        backContent.layer.contents = UIImage(named: "user_backg_img")?.cgImage
        
        setAvatar()
        
        NotificationCenter.default.addObserver(self, selector:#selector(notifiAction(notification:)),
                                                       name: NotifyContactChanged, object: nil)
//                self.view.layer.contents = UIImage(named: "user_backg_img")?.cgImage
//                self.view.contentMode = .scaleAspectFill
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
        avator.avaInfo = AvatarInfo.init(id: uid)
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
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
    
    private func populateView(){
            
        if let newUid = self.itemUID {
            if let obj = ContactItem.GetContact(newUid){
                self.itemData = obj
            }else{
                self.uid.text = newUid
//                                self.uid.isEditable = false
            }
        }
        
        guard let data = self.itemData else {
            return
        }
        
//                self.chatBtn.isHidden = false
//                self.delBarBtn.isEnabled = true
//                self.uid.isEditable = false
        self.uid.text = data.uid
        self.nickName.text = data.nickName
        self.memo.text = data.nickName
    
    
//                self.remarks.text = data.remark
//            if data.avatar != nil{
//                        self.avatar.image = UIImage.init(data: data.avatar!)
//            }
    }
    
    private func closeWindow(){
        self.dismiss(animated: true)
        self.navigationController?.popViewController(animated: true)
    }
//
//        @IBAction func SaveContact(_ sender: UIButton) {
//                let contact = ContactItem.init()
//                contact.uid = self.uid.text
//                contact.nickName = self.nickName.text
//                contact.remark = remarks.text
//                contact.avatar = self.avatar.image?.pngData()//TODO::Load avatar from netework
//                guard let err = ContactItem.UpdateContact(contact) else{
//                        NotificationCenter.default.post(name:NotifyContactChanged,
//                                                        object: nil, userInfo:nil)
//                        self.closeWindow()
//                        return
//                }
//
//                self.toastMessage(title: err.localizedDescription)
//        }
//
//        @IBAction func DeleteContact(_ sender: UIBarButtonItem) {
//                guard let uid = self.uid.text else{
//                        return
//                }
//
//                guard let err = ContactItem.DelContact(uid) else{
//                        NotificationCenter.default.post(name:NotifyContactChanged,
//                                                        object: nil, userInfo:nil)
//                        self.closeWindow()
//                        return
//                }
//
//                self.toastMessage(title: err.localizedDescription)
//        }
        
        
    @IBAction func StartChat(_ sender: UIButton) {
        guard self.uid.text != nil else{
            return
        }
        self.performSegue(withIdentifier: "ShowMessageDetailsSEG", sender: self)
    }
    
    
    /**/
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            
        if segue.identifier == "ShowMessageDetailsSEG"{
            let vc : MsgViewController = segue.destination as! MsgViewController
            vc.peerUid = self.uid.text!
        }
        
        if segue.identifier == "EditContactSegue" {
            let vc: ContactEditViewController = segue.destination as! ContactEditViewController
            vc.itemData = self.itemData
        }
    }
}
