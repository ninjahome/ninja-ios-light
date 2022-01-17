//
//  AvatarButton.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/7.
//

import UIKit
import CloudKit

enum AvatarButtonType {
        case wallet, contact, chatContact, chatGroup
}

struct AvatarInfo {
        var id: String
        var avatar: Data?
        init(id: String, avaData: Data?) {
                self.id = id
                self.avatar = avaData
        }
}

class AvatarButton: UIButton {
        var type: AvatarButtonType = .chatContact
//    init(type: AvatarButtonType, info: AvatarInfo) {
//        super.init(frame: .zero)
//        self.type = type
//        self.avaInfo = info
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
                super.touchesEnded(touches, with: event)
                switch type {
                case .contact:
                        guard let info = avaInfo else {
                                return
                        }

                        if let item = ContactItem.cache[info.id] {
                                let vc = instantiateViewController(storyboardName: "Main", viewControllerIdentifier: "ContactDetailsVC") as! ContactDetailsViewController
                                vc.itemData = item
                                UIViewController.topMostInApp?.navigationController?.pushViewController(vc, animated: true)
                        } else {
                                let vc = instantiateViewController(storyboardName: "Main", viewControllerIdentifier: "SearchDetailVC") as! SearchDetailViewController
                                vc.uid = info.id
                                UIViewController.topMostInApp?.navigationController?.pushViewController(vc, animated: true)
                        }
                default: break
                }
        }
    
        var avaInfo: AvatarInfo? {
                didSet {
                        switch self.type {
                        case .contact, .chatContact:
                                if let imgData = self.avaInfo?.avatar {
                                        self.setBackgroundImage(UIImage(data: imgData), for: .normal)
                                }
                        case .wallet:
                                guard let avaData = Wallet.shared.avatarData else {
                                        break
                                }
                                self.setBackgroundImage(UIImage(data: avaData), for: .normal)
                        case .chatGroup:
                                self.setBackgroundImage(UIImage.init(named: "ava"), for: .normal)
                        }
                        self.layer.masksToBounds = true
                }
        }
    
//        func getContactColor(id: String) -> String {
//                return ContactItem.GetAvatarColor(by: id)
//        }
//
//        func getWalletColor() -> String {
//                return Wallet.GenAvatarColor()
//        }
//
//        func getWalletText() -> String {
//                return Wallet.GenAvatarText()
//        }
//
//        func getContactText(id: String) -> String {
//                return ContactItem.GetAvatarText(by: id)
//        }
//
//        func getGroupText(id: String) -> String {
//                return GroupItem.GetAvatarText(by: id)
//        }
    
}
