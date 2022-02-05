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
        @IBOutlet weak var retry: UIButton?
        @IBOutlet weak var spinner: UIActivityIndicatorView?
        @IBOutlet weak var miniMapTrailing: NSLayoutConstraint!
        @IBOutlet weak var miniMapLeading: NSLayoutConstraint!
        
        var curMsg:MessageItem?
        override func prepareForReuse() {
                super.prepareForReuse()
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
        func updateMessageCell (by message: MessageItem, name:String, avatar:Data?) {
                self.curMsg = message
                let from = message.from

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
                        
                        self.avatar.setupSelf()
                        switch message.status {
                        case .faild:
                                spinner?.stopAnimating()
                                retry?.isHidden = false
                        case .sending:
                                spinner?.startAnimating()
                        default:
                                spinner?.stopAnimating()
                        }
                        nickname.text = ""
                } else {
                        let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
                        msgBackgroundView.image = img
                        miniMapLeading.constant = 8
                    
                        nickname.text = name
                        self.avatar.setup(id: from, avaData: avatar)
                }
                
                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }

}
