//
//  ContactTransferTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/27.
//

import UIKit

class ContactTransferTableViewCell: UITableViewCell {

        @IBOutlet weak var nickName: UILabel!
        @IBOutlet weak var avatar: AvatarButton!

        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }

        func initWith(details:ContactItem, idx: Int, account: AccountItem){
                self.nickName.text = details.alias

                guard let uid = details.uid else {
                        return
                }
                avatar.type = AvatarButtonType.chatContact
                avatar.avaInfo = AvatarInfo.init(id: uid, avaData: account.Avatar)
    }
}
