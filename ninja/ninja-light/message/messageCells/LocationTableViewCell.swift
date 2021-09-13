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
//        miniMapTrailing.constant = 0
//        miniMapLeading.constant = 0
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    func updateMessageCell (by message: MessageItem) {
        
        guard let from = message.from else {
            return
        }

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
            
//            avatar.setTitle(Wallet.GenAvatarText(), for: .normal)
//            avatar.backgroundColor = UIColor.init(hex: Wallet.GenAvatarColor())
            avatar.type = AvatarButtonType.wallet
            avatar.avaInfo = nil
            
            nickname.text = Wallet.GenAvatarText()
            
        } else {
            let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
            msgBackgroundView.image = img
            miniMapLeading.constant = 8
            
            avatar.type = AvatarButtonType.contact
            avatar.avaInfo = AvatarInfo.init(id: from)
//            let avaName = ContactItem.GetAvatarText(by: from)
//            avatar.setTitle(ContactItem.GetAvatarText(by: avaName), for: .normal)
//            let hex = ContactItem.GetAvatarColor(by: from)
//            avatar.backgroundColor = UIColor.init(hex: hex)
            let contactData = ContactItem.cache[from]
            nickname.text = contactData?.nickName ?? ContactItem.GetAvatarText(by: from)

        }
        
        time.text = formatTimeStamp(by: message.timeStamp)
    }


}
