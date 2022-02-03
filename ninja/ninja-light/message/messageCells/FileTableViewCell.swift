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
                }
        }
        
        @IBAction func openFileOrPlayVideo(_ sender: UIButton) {
                if cellMsg != nil {
//                        if let videoData = msg.payload as? videoMsg {
//                                playVideo(url: URL(fileURLWithPath: videoData.url))
//                        }
                }
        }

        func updateMessageCell (by message: MessageItem) {
                cellMsg = message
                msgBackgroundView.layer.cornerRadius = 8
                msgBackgroundView.clipsToBounds = true
                
                let from = message.from

                let contactData = CombineConntact.cache[from]
                
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
                        avatar.type = AvatarButtonType.contact
                        avatar.avaInfo = AvatarInfo.init(id: from, avaData: contactData?.account?.Avatar)
                        nickname.text = contactData?.GetNickName() ?? contactData?.peerID
                }

                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }
        

//        func playVideo(url: URL) {
//                let size = VideoFileManager.getVideoSize(videoURL: url)
//                print("video size\(size)")
//                let player = AVPlayer(url: url)
//                let vc = AVPlayerViewController()
//                vc.player = player
//                let window = getKeyWindow()
//                window?.rootViewController?.present(vc, animated: true, completion: {
//                        vc.player?.play()
//                })
//        }

}
