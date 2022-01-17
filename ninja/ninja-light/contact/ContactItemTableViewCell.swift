//
//  ContactItemTableViewCell.swift
//  ninja-light
//
//  Created by hyperorchid on 2021/4/8.
//

import UIKit

class ContactItemTableViewCell: UITableViewCell {

        @IBOutlet weak var nickName: UILabel!
        @IBOutlet weak var avatar: AvatarButton!
    
        override func awakeFromNib() {
            super.awakeFromNib()
                // Initialization code
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }

        func initWith(details:ContactItem, idx: Int, account: AccountItem) {
                if let alias = details.alias {
                        self.nickName.text = alias
                } else {
                        self.nickName.text = account.NickName
                }
                guard let uid = details.uid else {
                        return
                }
                avatar.type = AvatarButtonType.contact
                avatar.avaInfo = AvatarInfo.init(id: uid, avaData: account.Avatar)
        }
    
}
