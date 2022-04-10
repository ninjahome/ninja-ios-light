//
//  GroupItemTableViewCell.swift
//  immeta
//
//  Created by ribencong on 2021/12/28.
//

import UIKit

class GroupItemTableViewCell: UITableViewCell {
        
        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var groupName: UILabel!
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }
        
        func initWith(detail: GroupItem, idx: Int) {
                if let gp = detail.groupName, !gp.isEmpty{
                        self.groupName.text = gp
                }else{
                        self.groupName.text = detail.gid
                }
                
                if detail.avatar?.count  == 1{
                        ServiceDelegate.InitGorupAvatar(group:detail)
                }
                
                avatar.setup(id: detail.gid, avaData: detail.avatar)
        }

}
