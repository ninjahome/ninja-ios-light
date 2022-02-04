//
//  AvatarCollectionCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/17.
//

import UIKit

class AvatarCollectionCell: UICollectionViewCell {
        @IBOutlet weak var MemberIcon: AvatarButton!
    
        func initApperance(id: String) {
                var avaData: Data?
                if let contact = AccountItem.GetAccount(id) {
                        avaData = contact.Avatar
                } else {
                        let latest = AccountItem.loadAccountDetailFromChain(addr: id)
                        avaData = latest?.Avatar
                }
                MemberIcon.setup(id: id, avaData: avaData)
        }
}
