//
//  LocationTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/27.
//

import UIKit

class LocationTableViewCell: UITableViewCell {
        @IBOutlet weak var msgBackgroundView: UIImageView!
        @IBOutlet weak var locationStr: UILabel!

        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var nickname: UILabel!
        @IBOutlet weak var time: UILabel!

        @IBOutlet weak var miniMapTrailing: NSLayoutConstraint!
        @IBOutlet weak var miniMapLeading: NSLayoutConstraint!
    
        override func prepareForReuse() {
                super.prepareForReuse()
        }

        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }
    
        func updateMessageCell (by message: MessageItem) {
        
                let from = message.from
                let contactData = CombineConntact.cache[from]

                msgBackgroundView.layer.cornerRadius = 8
                msgBackgroundView.clipsToBounds = true
                
                if let localMsg = message.payload as? locationMsg {
                        print("*****LOCATION message.payload\(localMsg.la)。\(localMsg.lo)。\(localMsg.str)")
                        locationStr.text = localMsg.str
                }
                
                //message bubble
                if message.isOut {
                        let img = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
                        msgBackgroundView.image = img
                        miniMapTrailing.constant = 8
                        
                        avatar.type = AvatarButtonType.wallet
                        avatar.avaInfo = nil
                    
                        nickname.text = Wallet.shared.nickName ?? Wallet.GenAvatarText()
                } else {
                        let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
                        msgBackgroundView.image = img
                        miniMapLeading.constant = 8
                    
                        avatar.type = AvatarButtonType.contact
                        avatar.avaInfo = AvatarInfo.init(id: from, avaData: contactData?.account?.Avatar)
                        nickname.text = contactData?.GetNickName() ?? contactData?.peerID
                }
                
                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }


}
