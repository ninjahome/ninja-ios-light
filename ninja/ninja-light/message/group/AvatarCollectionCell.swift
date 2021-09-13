//
//  AvatarCollectionCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/17.
//

import UIKit

class AvatarCollectionCell: UICollectionViewCell {
//    var ava: Avatar?
//    var uid: String?
    
    @IBOutlet weak var MemberIcon: AvatarButton!
    
    func initApperance(id: String) {
        MemberIcon.type = AvatarButtonType.contact
        MemberIcon.avaInfo = AvatarInfo.init(id: id)
//        MemberIcon.backgroundColor = UIColor.init(hex: avatar.color)
//        MemberIcon.setTitle(avatar.text, for: .normal)
    }
    
}
