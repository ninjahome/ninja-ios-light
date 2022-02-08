//
//  MessageTableViewCell.swift
//  ninja-light
//
//  Created by akatuki on 2021/4/29.
//

import UIKit

func PopulatePeerCell(nickname:UILabel,
                             avatarBtn:AvatarButton,
                             from: String, name:String, avatar:Data?, isGroup:Bool){
        if !isGroup{
                initMemberInfos(nickname:nickname,
                                avatarBtn: avatarBtn,
                                pid: from, name: name, avatar: avatar)
        }else{
                let (peerName, peerAvatar) = ServiceDelegate.queryNickAndAvatar(pid: from) { name, avatar in
                        DispatchQueue.main.async {
                                initMemberInfos(nickname:nickname,
                                                avatarBtn: avatarBtn,
                                                pid: from, name: name, avatar: avatar)
                        }
                }
                initMemberInfos(nickname:nickname,
                                avatarBtn: avatarBtn,
                                pid: from, name: peerName, avatar: peerAvatar)
        }
}

private func initMemberInfos(nickname:UILabel,
                             avatarBtn:AvatarButton,
                             pid:String, name:String?, avatar:Data?){
        nickname.text = name
        avatarBtn.setup(id: pid, avaData: avatar)
}

class TxtTableViewCell: UITableViewCell {
        
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
                        retry?.isHidden = false
                        spinner?.stopAnimating()
                }
        }
        
        func updateMessageCell (by message: MessageItem, name:String, avatar:Data?, isGroup:Bool) {
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
                        self.avatar.setupSelf()
                        self.nickname.text = ""
                } else {
                        msgBackgroundView.image = ourImg
                        PopulatePeerCell(nickname:self.nickname,
                                         avatarBtn: self.avatar,
                                         from: from, name: name, avatar: avatar, isGroup: isGroup)
                }
                
                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }
        
        
}
