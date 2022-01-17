//
//  GroupItemTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/28.
//

import UIKit

class GroupItemTableViewCell: UITableViewCell {
        
        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var groupName: UILabel!
        
        override func awakeFromNib() {
        super.awakeFromNib()
                // Initialization code
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)

                // Configure the view for the selected state
        }
        
        func initWith(detail: GroupItem, idx: Int) {
                self.groupName.text = detail.groupName
                guard let gid = detail.gid else { return }
                avatar.type = AvatarButtonType.chatGroup
                avatar.avaInfo = AvatarInfo.init(id: gid, avaData: detail.avatar)
        }

}
