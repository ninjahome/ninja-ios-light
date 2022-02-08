//
//  FileTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/9.
//

import UIKit
import AVKit
import AVFoundation

class FileTableViewCell: UITableViewCell {

        @IBOutlet weak var msgBackgroundView: UIImageView!
//        @IBOutlet weak var thumbtailImage: UIImageView!

        @IBOutlet weak var openFileBtn: UIButton!
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
                
                guard let msg = self.cellMsg else{
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
        
        @IBAction func openFileOrPlayVideo(_ sender: UIButton) {
                if cellMsg != nil {
                }
        }

        func updateMessageCell (by message: MessageItem, name:String, avatar:Data?, isGroup:Bool) {
                cellMsg = message
                msgBackgroundView.layer.cornerRadius = 8
                msgBackgroundView.clipsToBounds = true
                
                let from = message.from

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
                        
                        self.avatar.setupSelf()
                        nickname.text = ""
                } else {
                        nickname.text = name
                        self.avatar.setup(id: from, avaData: avatar)
                        
                }

                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }
}
