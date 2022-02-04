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
        @IBOutlet weak var retry: UIButton?
        @IBOutlet weak var spinner: UIActivityIndicatorView?
        
        let inMsgImg = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
        let ourImg = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
        
        var curMsg:MessageItem?
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
        
        @IBAction func resendFailedMsg(_ sender: Any) {
                guard let msg = self.curMsg else{
                        print("------>>>no valid msg in current cell")
                        return
                }
                msg.status = .sending
                spinner?.startAnimating()
                retry?.isHidden = true
                if let err = WebsocketSrv.shared.SendMessage(msg: msg){
                        print("------>>> retry failed:=>", err)
                        msg.status = .faild
                }
        }
        
        func updateMessageCell (by message: MessageItem) {
                self.curMsg = message
                let from = message.from
                guard let msgText = message.payload as? txtMsg else{
                        msgLabel.text = "Invalid Text MSG"
                        return
                }
                msgLabel.text = msgText.txt
                if message.isOut {
                        switch message.status {
                        case .faild:
                                spinner?.stopAnimating()
                                retry?.isHidden = false
                        case .sending:
                                spinner?.startAnimating()
                        default:
                                spinner?.stopAnimating()
                        }
                        msgBackgroundView.image = inMsgImg
                        avatar.type = AvatarButtonType.wallet
                        avatar.avaInfo = nil
                        nickname.text = "" // Wallet.shared.nickName ?? Wallet.GenAvatarText()
                } else {
                        msgBackgroundView.image = ourImg
                        avatar.type = AvatarButtonType.contact
                        let(name, avatarData) = ServiceDelegate.queryNickAndAvatar(pid: from) { name, avatarData in
                                DispatchQueue.main.async {
                                        self.initCellMeta(pid: from, name: name, aData: avatarData)
                                }
                        }
                        self.initCellMeta(pid: from, name: name, aData: avatarData)
                }
                
                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }
        private func initCellMeta(pid:String, name:String?, aData:Data?){
                avatar.avaInfo = AvatarInfo.init(id: pid, avaData: aData)
                nickname.text = name ??  pid
        }
}
