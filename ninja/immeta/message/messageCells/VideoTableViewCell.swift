//
//  VideoTableViewCell.swift
//  immeta
//
//  Created by ribencong on 2022/1/28.
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
        
        private var widthConstraint: NSLayoutConstraint!
        private var heightConstraint: NSLayoutConstraint!
        
        var cellMsg: MessageItem?
        var isHorizon:Bool = false
        var scaler:CGFloat = 1.0
        var videoWithHash:videoMsgWithHash?
        
        func configure(){
                if isHorizon{
                        widthConstraint.constant = 120 * scaler
                        heightConstraint.constant = 67.5 * scaler
                }else{
                        widthConstraint.constant = 67.5 * scaler
                        heightConstraint.constant = 120 * scaler
                }
        }
        override func prepareForReuse() {
                super.prepareForReuse()
                
                spinner?.stopAnimating()
                retry?.isHidden = true
        }
        
        override func awakeFromNib() {
                super.awakeFromNib()
                let longTap = UILongPressGestureRecognizer(target: self,
                                                           action: #selector(VideoTableViewCell.longPress(sender:)))
                self.addGestureRecognizer(longTap)
                scaler = msgBackgroundView.contentScaleFactor
                widthConstraint = msgBackgroundView.widthAnchor.constraint(equalToConstant: 67.5 * scaler)
                heightConstraint = msgBackgroundView.heightAnchor.constraint(equalToConstant: 120 * scaler)
                widthConstraint.isActive = true
                heightConstraint.isActive = true
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
        private func playByHash(){
                guard let vc = getKeyWindow()?.rootViewController else{
                        return
                }
                vc.showIndicator(withTitle: "", and: "loading".locStr)
                ServiceDelegate.workQueue.async {
                        let meta = self.videoWithHash!
                        let url = ServiceDelegate.LoadVideoByHash(has: meta.has!, key: meta.key)
                        vc.hideIndicator()
                        guard let url = url else{
                                vc.toastMessage(title: "video expired".locStr)
                                return
                        }
                        DispatchQueue.main.async {
                                self.playByUrl(url:url)
                        }
                }
        }
        
        private func playByUrl(url:URL){
                let player = AVPlayer(url: url)
                let vc = AVPlayerViewController()
                vc.player = player
                
                let window = getKeyWindow()
                window?.rootViewController?.present(vc, animated: true, completion: {
                        vc.player?.play()
                })
        }
        
        @IBAction func PlayVideo(_ sender: UIButton) {
               
                if nil != self.videoWithHash {
                        self.playByHash()
                        return
                }
        }
        
        func updateHashVideoCell (message: MessageItem, name:String, avatar:Data?, isGroup:Bool) {
                cellMsg = message
                msgBackgroundView.layer.cornerRadius = 8
                msgBackgroundView.clipsToBounds = true
                guard let hv = message.payload as? videoMsgWithHash else{
                        return
                }
                self.videoWithHash = hv
                guard let thumb = hv.thumbData else{
                        return
                }
                isHorizon = hv.isHorizon
                let thumbImg = UIImage(data: thumb)
                playVideBtn.layer.contents =  thumbImg?.cgImage
                playVideBtn.layer.contentsGravity = CALayerContentsGravity.resizeAspectFill;
                
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
                                         from: message.from, name: name, avatar: avatar, isGroup: isGroup)
                }
                
                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }
        
      
        private func saveVideoByHash(has:String, key:Data?){
                guard let vc = getKeyWindow()?.rootViewController else{
                        return
                }
                vc.showIndicator(withTitle: "", and: "saving".locStr)
                ServiceDelegate.workQueue.async {
                        let urlOfHash = ServiceDelegate.getVideoUrlByHash(has: has, key:key)
                        vc.hideIndicator()
                        guard let url = urlOfHash else{
                                vc.toastMessage(title: "video expired".locStr, duration: 1)
                                return
                        }
                        self.copyDataBy(url:url)
                }
        }
        
        @objc func longPress(sender: UILongPressGestureRecognizer
        ) {
                if let has = self.videoWithHash?.has {
                        self.saveVideoByHash(has: has, key: self.videoWithHash?.key)
                        return
                }
        }
        
        private func copyDataBy(url:URL){DispatchQueue.main.async {
                
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
        }}
        
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
