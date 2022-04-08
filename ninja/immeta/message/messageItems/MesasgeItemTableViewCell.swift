//
//  MesasgeItemTableViewCell.swift
//  immeta
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
        
        func initWith(details: ChatItem) {
                
                let itemId = details.ItemID
                var avaData: Data?
                var nickName:String?
                
                if details.isGroup {
                        if let grp = GroupItem.cache[itemId] {
                                if grp.avatar?.count  == nilAvatarLen{
                                        ServiceDelegate.InitGorupAvatar(group:grp)
                                }
                                avaData = grp.avatar
                                nickName = grp.groupName
                        }else{
                                GroupItem.CheckGroupIsDeleted(gid:itemId)
                        }
                        
                       
                } else {
                        (nickName, avaData) = chatItemInfo(pid: itemId)
                }
                
                avatar.setup(id: itemId, avaData: avaData,showDetails: false)
                if let name = nickName, !name.isEmpty{
                        self.nickName.text = name
                }else{
                        self.nickName.text = itemId
                }
                
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
                
                return ServiceDelegate.queryNickAndAvatar(pid: pid) {name, data in
                        
                        DispatchQueue.main.async {
                                self.avatar.setup(id: pid, avaData: data)
                                if let n = name, !n.isEmpty{
                                        self.nickName.text = n
                                }else{
                                        self.nickName.text = pid
                                }
                        }
                }
        }
}
