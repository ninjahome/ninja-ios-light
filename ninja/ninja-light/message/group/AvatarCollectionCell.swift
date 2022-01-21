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
                MemberIcon.type = AvatarButtonType.contact
                var avaData: Data?
                if let contact = AccountItem.GetAccount(id) {
                        avaData = contact.Avatar
                }
                MemberIcon.avaInfo = AvatarInfo.init(id: id, avaData: avaData)
        }
}
