//
//  VideoTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/1/28.
//

import UIKit
import AVKit
import AVFoundation
extension NSLayoutConstraint {
    func constraintWithMultiplier(_ multiplier: CGFloat) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: self.firstItem!, attribute: self.firstAttribute, relatedBy: self.relation, toItem: self.secondItem, attribute: self.secondAttribute, multiplier: multiplier, constant: self.constant)
    }
}
class VideoTableViewCell: UITableViewCell {
        
        @IBOutlet weak var msgBackgroundView: UIImageView!
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
                let longTap = UILongPressGestureRecognizer(target: self,
                                                           action: #selector(VideoTableViewCell.longPress(sender:)))
                self.addGestureRecognizer(longTap)
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
        
        func updateMessageCell (by message: MessageItem, name:String, avatar:Data?, isGroup:Bool) {
                cellMsg = message
                msgBackgroundView.layer.cornerRadius = 8
                msgBackgroundView.clipsToBounds = true
                
                let from = message.from
                if let video = message.payload as? videoMsg{
                        playVideBtn.layer.contents = video.thumbnailImg.cgImage
                        playVideBtn.layer.contentsGravity = CALayerContentsGravity.resizeAspect;
                        playVideBtn.layer.transform = CATransform3DMakeRotation(0.0, -90.0 / 180.0 * .pi, 0.0, 1.0)
                        msgBackgroundView.layer.frame = CGRect(x: 0, y: 0, width: 160, height: 90)
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
                        self.avatar.setupSelf()
                        self.nickname.text = ""
                } else {
                        PopulatePeerCell(nickname:self.nickname,
                                         avatarBtn: self.avatar,
                                         from: from, name: name, avatar: avatar, isGroup: isGroup)
                }
                
                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }
        
        @objc func longPress(sender: UILongPressGestureRecognizer
        ) {
                guard let videoData = cellMsg?.payload as? videoMsg else{
                        print("------>>> invalid video file")
                        return
                }
                guard let url = videoData.tmpUrl() else{
                        print("------>>> tmp video file url invalid")
                        return
                }
                let selectorToCall = #selector(VideoTableViewCell.videoSaved(_:didFinishSavingWithError:context:))
                let alert = UIAlertController(title: "Choose opertion".locStr, message: nil, preferredStyle: .actionSheet)
                let action = UIAlertAction(title: "Save to album".locStr, style: .default) { (_) in
                        UISaveVideoAtPathToSavedPhotosAlbum(url.path, self, selectorToCall, nil)
                }
                let cancel = UIAlertAction(title: "Cancel".locStr, style: .cancel, handler: nil)
                alert.addAction(action)
                alert.addAction(cancel)
                
                let window = getKeyWindow()
                window?.rootViewController?.present(alert, animated: true)
                
        }
        @objc func videoSaved(_ video: String, didFinishSavingWithError error: NSError!, context: UnsafeMutableRawPointer){
                if let theError = error {
                        print("------>>>error saving the video = \(theError)")
                        return
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                        getKeyWindow()?.rootViewController?.toastMessage(title: "Save success".locStr, duration: 1)
                })
        }
}
