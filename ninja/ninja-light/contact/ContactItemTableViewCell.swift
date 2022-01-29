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

        func initWith(details: CombineConntact) {
                self.nickName.text = details.GetNickName() ?? details.peerID
                avatar.type = AvatarButtonType.contact
                avatar.avaInfo = AvatarInfo.init(id: details.peerID, avaData: details.account?.Avatar)
        }
}
