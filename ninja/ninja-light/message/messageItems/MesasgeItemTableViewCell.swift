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
                        (nickName, avaData) = chatItemInfo(pid: itemId)
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
        
        private func chatItemInfo(pid:String)->(String?, Data?){
                if let acc = CombineConntact.cache[pid]{
                        return (acc.GetNickName(), acc.account?.Avatar)
                }
                if let acc = AccountItem.extraCache[pid]{
                        return (acc.NickName, acc.Avatar)
                }
                
                ServiceDelegate.workQueue.async {
                        guard let acc = AccountItem.extraLoad(pid: pid) else{
                                return
                        }
                        DispatchQueue.main.async {
                                self.avatar.avaInfo = AvatarInfo.init(id: pid, avaData: acc.Avatar)
                                self.nickName.text = acc.NickName ?? pid
                        }
                }
                
                return (nil, nil)
        }
}
