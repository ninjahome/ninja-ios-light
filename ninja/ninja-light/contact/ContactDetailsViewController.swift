//
//  NewContactViewController.swift
//  ninja-light
//
//  Created by hyperorchid on 2021/4/8.
//

import UIKit

class ContactDetailsViewController: UIViewController {
        
        @IBOutlet weak var uid: UITextView!
        @IBOutlet weak var remarks: UITextView!
        @IBOutlet weak var nickName: UITextField!
        @IBOutlet weak var avatar: UIImageView!
        @IBOutlet weak var chatBtn: UIButton!
        @IBOutlet weak var delBarBtn: UIBarButtonItem!
        
        
        var itemUID:String?
        var itemData:ContactItem?
        
        override func viewDidLoad() {
                super.viewDidLoad()
            
                self.hideKeyboardWhenTappedAround()
                self.populateView()
            
//                self.view.layer.contents = UIImage(named: "user_backg_img")?.cgImage
//                self.view.contentMode = .scaleAspectFill
        }
        
        private func populateView(){
                
                if let newUid = self.itemUID{
                        if let obj = ContactItem.GetContact(newUid){
                                self.itemData = obj
                        }else{
                                self.uid.text = newUid
                                self.uid.isEditable = false
                        }
                }
                
                guard let data = self.itemData else {
                        return
                }
                
                self.chatBtn.isHidden = false
                self.delBarBtn.isEnabled = true
                self.uid.isEditable = false
                self.uid.text = data.uid
                self.nickName.text = data.nickName
                self.remarks.text = data.remark
                if data.avatar != nil{
                        self.avatar.image = UIImage.init(data: data.avatar!)
                }
        }
    
        private func closeWindow(){
                self.dismiss(animated: true)
                self.navigationController?.popViewController(animated: true)
        }
        
        @IBAction func SaveContact(_ sender: UIButton) {
                let contact = ContactItem.init()
                contact.uid = self.uid.text
                contact.nickName = self.nickName.text
                contact.remark = remarks.text
//                contact.avatar = self.avatar.image?.pngData()//TODO::Load avatar from netework
                guard let err = ContactItem.UpdateContact(contact) else{
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                        object: nil, userInfo:nil)
                        self.closeWindow()
                        return
                }
                
                self.toastMessage(title: err.localizedDescription)
        }
        
        @IBAction func DeleteContact(_ sender: UIBarButtonItem) {
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
        }
}
