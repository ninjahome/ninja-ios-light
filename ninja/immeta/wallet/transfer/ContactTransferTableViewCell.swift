//
//  ContactTransferTableViewCell.swift
//  immeta
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
        
        func initWith(details:CombineConntact, idx: Int){
                self.nickName.text = details.GetNickName() ?? details.peerID
                self.avatar.setup(id: details.peerID, avaData:details.account?.Avatar)
        }
}
