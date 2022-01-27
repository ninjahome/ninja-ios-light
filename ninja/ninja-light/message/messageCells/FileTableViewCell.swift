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
                if let msg = cellMsg {
                        var cliMsg: CliMessage?
                        if let videoData = msg.payload as? videoMsg {
                                cliMsg = CliMessage.init(to: msg.to!, videoUrl: URL(fileURLWithPath: videoData.url), groupId: msg.groupId!)
                        }
                        if let fileData = msg.payload as? fileMsg {
                                openFileBtn.isHidden = true
                                cliMsg = CliMessage.init(to: msg.to!, fileUrl: fileData.url!, groupId: msg.groupId!)
                        }
                        guard let resendCli = cliMsg else {
                                return
                        }

                        WebsocketSrv.shared.SendIMMsg(cliMsg: resendCli, retry: true) { [self] in
                                self.retry?.isHidden = true
                                self.spinner?.startAnimating()
                        } onCompletion: { success in
                                if !success {
                                        MessageItem.resetSending(msgid: resendCli.timestamp!, to: resendCli.to!, success: success)
                                        self.updateMessageCell(by: msg)
                                }
                                
                        }
                }
        }
        
        @IBAction func openFileOrPlayVideo(_ sender: UIButton) {
                if let msg = cellMsg {
                        if let videoData = msg.payload as? videoMsg {
                                playVideo(url: URL(fileURLWithPath: videoData.url))
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
                
                if cellMsg?.typ == .video {
                        if let video = cellMsg?.payload as? videoMsg,
                           let image = UIImage(data: video.thumbnailImg) {
                                openFileBtn.layer.contents = image.cgImage
                        }
                }

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
                        let acc = AccountItem.GetAccount(from)
                        avatar.type = AvatarButtonType.contact
                        avatar.avaInfo = AvatarInfo.init(id: from, avaData: acc?.Avatar)

                        if let contactData = ContactItem.cache[from],
                           let alias = contactData.alias {
                                nickname.text = alias
                        } else {
                                nickname.text = acc?.NickName
                        }
                }

                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }
        

        func playVideo(url: URL) {
                let size = VideoFileManager.getVideoSize(videoURL: url)
                print("video size\(size)")
                let player = AVPlayer(url: url)
                let vc = AVPlayerViewController()
                vc.player = player
                let window = getKeyWindow()
                window?.rootViewController?.present(vc, animated: true, completion: {
                        vc.player?.play()
                })
        }

}
