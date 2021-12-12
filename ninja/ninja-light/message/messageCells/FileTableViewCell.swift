//
//  FileTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/9.
//

import UIKit
import AVFoundation

class FileTableViewCell: UITableViewCell {

        @IBOutlet weak var msgBackgroundView: UIImageView!
        @IBOutlet weak var thumbtailImage: UIImageView!

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
                                MessageItem.resetSending(cliMsg: cliMsg, success: success)

                                if success {
                                        msg.status = .sent
                                }
                                self.updateMessageCell(by: msg)
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
                           let vurl = video.url {
                                thumbtailImage.image = thumbnailImageOfVideoInVideoURL(videoURL: vurl)
                                thumbtailImage.contentMode = .scaleAspectFill
                                thumbtailImage.clipsToBounds = true
                        }
                }

                

//                ShowImageDetail.show(imageView: thumbtailImage)

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
        
        private func thumbnailImageOfVideoInVideoURL(videoURL: URL) -> UIImage? {
                let asset = AVURLAsset(url: videoURL as URL, options: [:])
                
                let imageGenerator = AVAssetImageGenerator(asset: asset)

                imageGenerator.appliesPreferredTrackTransform = true

                var actualTime: CMTime = CMTimeMake(value: 0, timescale: 0)

                guard let cgImage = try? imageGenerator.copyCGImage(at: CMTimeMakeWithSeconds(0.0, preferredTimescale: 600), actualTime: &actualTime) else {
                        return nil
                }

                let thumbnail = UIImage(cgImage: cgImage)

                return thumbnail
        }


}
