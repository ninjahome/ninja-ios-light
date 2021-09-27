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
            // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
    }

    func initWith(details:ContactItem, idx: Int){
//                if details.avatar != nil{
//                        self.avatar.image = UIImage.init(data: details.avatar!)
//                }
            self.nickName.text = details.nickName

//            let avaName = ContactItem.GetAvatarText(by: details.uid!)
//            avatar.setTitle(avaName, for: .normal)
//            let hex = ContactItem.GetAvatarColor(by: details.uid!)
//            avatar.backgroundColor = UIColor.init(hex: hex)
//
        guard let uid = details.uid else {
            return
        }
        avatar.type = AvatarButtonType.chatContact
        avatar.avaInfo = AvatarInfo.init(id: uid)
       
    }
}
