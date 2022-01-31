//
//  MessageTableViewCell.swift
//  ninja-light
//
//  Created by akatuki on 2021/4/29.
//

import UIKit

class MessageTableViewCell: UITableViewCell {
        
        @IBOutlet weak var msgBackgroundView: UIImageView!
        
        @IBOutlet weak var msgLabel: UITextView!
        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var nickname: UILabel!
        @IBOutlet weak var time: UILabel!
        
        @IBOutlet weak var spinner: UIActivityIndicatorView?
        
        override func prepareForReuse() {
                super.prepareForReuse()
                spinner?.stopAnimating()
        }
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }
        
        
        func updateMessageCell (by message: MessageItem) {
                
                if let msgText = message.payload as? String {
                        msgLabel.text = msgText
                }
                
                guard let from = message.from else {
                        return
                }
                
                if message.isOut {
                        switch message.status {
                        case .faild:
                                spinner?.stopAnimating()
                        case .sending:
                                spinner?.startAnimating()
                        default:
                                spinner?.stopAnimating()
                        }
                        
                        let img = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
                        msgBackgroundView.image = img
                        avatar.type = AvatarButtonType.wallet
                        avatar.avaInfo = nil
                        nickname.text = Wallet.shared.nickName ?? Wallet.GenAvatarText()
                } else {
                        let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
                        msgBackgroundView.image = img
                        
                        avatar.type = AvatarButtonType.contact
                        
                        let contactData = CombineConntact.cache[from]
                        avatar.avaInfo = AvatarInfo.init(id: from, avaData: contactData?.account?.Avatar)
                        nickname.text = contactData?.GetNickName() ?? contactData?.peerID
                }
                
                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }
}
