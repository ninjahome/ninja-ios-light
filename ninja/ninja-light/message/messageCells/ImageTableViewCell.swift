//
//  ImageTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/27.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

        @IBOutlet weak var msgBackgroundView: UIImageView!
        @IBOutlet weak var imageMsg: UIImageView!

        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var nickname: UILabel!
        @IBOutlet weak var time: UILabel!

        @IBOutlet weak var spinner: UIActivityIndicatorView?

        @IBOutlet weak var retry: UIButton?

var cellMsg: MessageItem?

        override func prepareForReuse() {
                super.prepareForReuse()

                spinner?.stopAnimating()
                retry?.isHidden = true
        }

        override func awakeFromNib() {
                super.awakeFromNib()
                // Initialization code
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
                // Configure the view for the selected state
        }
    
        @IBAction func retry(_ sender: UIButton) {
                if let msg = cellMsg {
                        let cliMsg = CliMessage.init(to: msg.to!, imgData: msg.payload as! Data, groupId: msg.groupId)

                        WebsocketSrv.shared.SendIMMsg(cliMsg: cliMsg, retry: true) { [self] in
                                self.retry?.isHidden = true
                                self.spinner?.startAnimating()
                        } onCompletion: { success in
                                if !success {
                                        MessageItem.resetSending(msgid: msg.timeStamp, to: msg.to!, success: success)
                                        self.updateMessageCell(by: msg)
                                }
                                
                        }
                }
        }
    
        func updateMessageCell (by message: MessageItem) {
                cellMsg = message
                msgBackgroundView.layer.cornerRadius = 8
                msgBackgroundView.clipsToBounds = true

                guard let from = message.from else {
                        return
                }

                imageMsg.image = UIImage(data: message.payload as! Data)
                imageMsg.contentMode = .scaleAspectFill
                imageMsg.clipsToBounds = true

                ShowImageDetail.show(imageView: imageMsg)

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

                        avatar.type = AvatarButtonType.wallet
                        avatar.avaInfo = nil

                        nickname.text = Wallet.GenAvatarText()

                } else {

                        avatar.type = AvatarButtonType.contact
                        avatar.avaInfo = AvatarInfo.init(id: from)

                        let contactData = ContactItem.cache[from]
                        nickname.text = contactData?.nickName ?? ContactItem.GetAvatarText(by: from)

                }

                time.text = formatTimeStamp(by: message.timeStamp)
        }

}
