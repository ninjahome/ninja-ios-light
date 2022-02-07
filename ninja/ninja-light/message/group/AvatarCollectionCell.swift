//
//  AvatarCollectionCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/17.
//

import UIKit

class AvatarCollectionCell: UICollectionViewCell {
        @IBOutlet weak var MemberIcon: AvatarButton!
        @IBOutlet weak var nickName: UILabel!
        @IBOutlet weak var groupLeaderImg: UIImageView!
        
        func initApperance(id: String,isMember:Bool = true) {
                
                if id == Wallet.shared.Addr{
                        MemberIcon.setupSelf()
                        nickName.text = Wallet.shared.nickName
                        return
                }
                
                let (name, avatar) = ServiceDelegate.queryNickAndAvatar(pid: id) { name, avatar in
                        DispatchQueue.main.async {
                                self.MemberIcon.setup(id: id, avaData: avatar)
                                self.nickName.text = name ?? ""
                        }
                }
                MemberIcon.setup(id: id, avaData: avatar)
                nickName.text = name ?? ""
                groupLeaderImg.isHidden = isMember
        }
}
