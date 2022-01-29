//
//  MesasgeItemTableViewCell.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import UIKit

class MesasgeItemTableViewCell: UITableViewCell {

        @IBOutlet weak var unreadView: UIView!
        @IBOutlet weak var unread: UILabel!
        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var nickName: UILabel!
        @IBOutlet weak var LastMsg: UILabel!
        @IBOutlet weak var lastMsgTime: UILabel!
    
        override func prepareForReuse() {
                super.prepareForReuse()
                avatar.setBackgroundImage(nil, for: .normal)
        }

        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }

        func initWith(details: ChatItem, idx:Int) {

                let itemId = details.ItemID
                var avaData: Data?
                var nickName:String?
                
                if details.isGroup {
                        avatar.type = AvatarButtonType.chatGroup
                        let grp = GroupItem.GetGroup(itemId)//TODO::
                        avaData = grp?.avatar
                        nickName = grp?.groupName
                } else {
                        avatar.type = AvatarButtonType.chatContact
                        let acc = CombineConntact.cache[itemId]
                        avaData = acc?.account?.Avatar
                        nickName = acc?.GetNickName()
                }

                avatar.avaInfo = AvatarInfo.init(id: itemId, avaData: avaData)
                self.nickName.text = nickName ?? itemId
                self.LastMsg.text = details.LastMsg
                self.lastMsgTime.text = formatMsgTimeStamp(by: details.updateTime)

                if details.unreadNo > 0 {
                        self.unread.text = "\(details.unreadNo)"
                        self.unreadView.isHidden = false
                } else {
                        self.unreadView.isHidden = true
                        self.unread.text = ""
                }

        }
}
