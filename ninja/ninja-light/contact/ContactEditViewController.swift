//
//  ContactEditViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/7/8.
//

import UIKit

class ContactEditViewController: UIViewController {

    @IBOutlet weak var nickName: UITextField!
    @IBOutlet weak var memo: UITextView!
    
    var itemData: ContactItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        nickName.text = itemData?.nickName
        memo.text = itemData?.remark
    }
     
    @IBAction func saveEdit(_ sender: UIButton) {
        
        let contact = ContactItem.init()
        contact.uid = itemData?.uid
        contact.nickName = self.nickName.text
        contact.remark = self.memo.text
//        contact.avatar = self.avatar.image?.pngData()
        guard let err = ContactItem.UpdateContact(contact) else{
               NotificationCenter.default.post(name:NotifyContactChanged,
                                               object: contact, userInfo:nil)
               self.closeWindow()
               return
        }

        self.toastMessage(title: err.localizedDescription)
    }
    
    private func closeWindow(){
            self.dismiss(animated: true)
            self.navigationController?.popViewController(animated: true)
    }

}
