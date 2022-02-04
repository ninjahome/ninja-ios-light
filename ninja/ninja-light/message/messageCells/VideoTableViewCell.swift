//
//  VideoTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/1/28.
//

import UIKit
import AVKit
import AVFoundation

class VideoTableViewCell: UITableViewCell {
        
        @IBOutlet weak var msgBackgroundView: UIImageView!
        //        @IBOutlet weak var thumbtailImage: UIImageView!
        
        @IBOutlet weak var playVideBtn: UIButton!
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
        
        @IBAction func PlayVideo(_ sender: UIButton) {
                guard let msg = cellMsg else{
                        print("------>>> empty message")
                        return
                }
                
                guard let videoData = msg.payload as? videoMsg else{
                        print("------>>> invalid video file")
                        return
                }
             
                guard let url = videoData.tmpUrl() else{
                        print("------>>> tmp video file url invalid")
                        return
                }
                let player = AVPlayer(url: url)
                let vc = AVPlayerViewController()
                vc.player = player
                let window = getKeyWindow()
                window?.rootViewController?.present(vc, animated: true, completion: {
                        vc.player?.play()
                })
        }
        
        func updateMessageCell (by message: MessageItem) {
                cellMsg = message
                msgBackgroundView.layer.cornerRadius = 8
                msgBackgroundView.clipsToBounds = true
                
                let from = message.from
                if let video = message.payload as? videoMsg{
                        playVideBtn.layer.contents = video.thumbnailImg.cgImage
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
