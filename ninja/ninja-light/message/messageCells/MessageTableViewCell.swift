//
//  MessageTableViewCell.swift
//  ninja-light
//
//  Created by akatuki on 2021/4/29.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var msgBackgroundView: UIImageView!
//    @IBOutlet weak var msgLabel: UILabel!
    
    @IBOutlet weak var msgLabel: UITextView!
    @IBOutlet weak var avatar: AvatarButton!
    @IBOutlet weak var nickname: UILabel!
    @IBOutlet weak var time: UILabel!
    
    
//    var trailingConstrain: NSLayoutConstraint!
//    var leadingConstrain:NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
//        leadingConstrain.isActive = false
//        trailingConstrain.isActive = false
        
//        print("self.reuseIdentifier\(String(describing: self.reuseIdentifier))")
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
//        msgBackgroundView.layer.cornerRadius = 8
//        msgBackgroundView.clipsToBounds = true
//
//        trailingConstrain = msgBackgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
//        leadingConstrain = msgBackgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20)
        
        if let msgText = message.payload as? String {
            msgLabel.text = msgText
        }
        
        guard let from = message.from else {
            return
        }
        
        //message bubble
        if message.isOut {
//            let frame = msgBackgroundView.frame
//            let imgView = UIImageView.init(frame: frame)
            let img = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
            msgBackgroundView.image = img
//            msgBackgroundView.addSubview(imgView)
//            msgBackgroundView.insertSubview(imgView, at: 0)
//            trailingConstrain.isActive = true
            
//            avatar.setTitle(Wallet.GenAvatarText(), for: .normal)
//            avatar.backgroundColor = UIColor.init(hex: Wallet.GenAvatarColor())
            avatar.type = AvatarButtonType.wallet
            avatar.avaInfo = nil
            nickname.text = Wallet.GenAvatarText()
        } else {
            let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
            msgBackgroundView.image = img
            
            avatar.type = AvatarButtonType.contact
            avatar.avaInfo = AvatarInfo.init(id: from)
//            let avaName = ContactItem.GetAvatarText(by: from)
//            avatar.setTitle(ContactItem.GetAvatarText(by: avaName), for: .normal)
//            let hex = ContactItem.GetAvatarColor(by: from)
//            avatar.backgroundColor = UIColor.init(hex: hex)
//            leadingConstrain.isActive = true
            let contactData = ContactItem.cache[from]
            nickname.text = contactData?.nickName ?? ContactItem.GetAvatarText(by: from)
        }
        
        time.text = formatTimeStamp(by: message.timeStamp)

        
    }

}
