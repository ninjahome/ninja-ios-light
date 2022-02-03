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
                guard let im =  cellMsg else{
                        return
                }
                if let err = WebsocketSrv.shared.SendMessage(msg: im){
                        print("------>>> retry send err:", err)
                        return
                }
        }
    
        func updateMessageCell (by message: MessageItem) {
                cellMsg = message
                msgBackgroundView.layer.cornerRadius = 8
                msgBackgroundView.clipsToBounds = true
                let from = message.from
                let img = message.payload as? imgMsg
                imageMsg.image = UIImage(data: img?.content ?? Data())//TODO::
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

                        nickname.text = Wallet.shared.nickName ?? Wallet.GenAvatarText()

                } else {
                        let contactData = CombineConntact.cache[from]
                        avatar.type = AvatarButtonType.contact
                        avatar.avaInfo = AvatarInfo.init(id: from, avaData: contactData?.account?.Avatar)
                        nickname.text = contactData?.GetNickName() ?? contactData?.peerID
                }

                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }

}
