//
//  SearchDetailViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/7/8.
//

import UIKit

class SearchDetailViewController: UIViewController {

    
    @IBOutlet weak var backContent: UIView!
    @IBOutlet weak var avatar: UIButton!
    @IBOutlet weak var uidText: UILabel!
        
    var uid: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
 
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uidText.text = uid
        
        let avatarText = (uid?.prefix(2))!
        avatar.setTitle(String(avatarText), for: .normal)
        
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
        guard let err = ContactItem.UpdateContact(contact) else{
                NotificationCenter.default.post(name:NotifyContactChanged,
                                                object: nil, userInfo:nil)
                return
        }

        self.toastMessage(title: err.localizedDescription)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SaveNewContactSeg" {

            let contact = ContactItem.init()
            contact.uid = self.uid

            let vc = segue.destination as! ContactDetailsViewController
            vc.itemUID = self.uid
            vc.itemData = contact

        }
        
        if segue.identifier == "StrangerMessageDetailSeg" {
            guard let id = self.uid else {
                return
            }
            let vc : MsgViewController = segue.destination as! MsgViewController
            vc.peerUid = id
        }
    }
    
    @IBAction func chatWith(_ sender: Any) {
        guard self.uid != nil else {
                return
        }
//        self.performSegue(withIdentifier: "ShowMessageDetailsSEG", sender: self)

    }
    
    
}
