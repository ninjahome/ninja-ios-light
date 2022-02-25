//
//  ImageTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/27.
//

import UIKit
import MBProgressHUD

class ImageTableViewCell: UITableViewCell {
        
        private let showBigDuration = 0.6
        private let showOriginalDuration = 0.6

        
        @IBOutlet weak var msgBackgroundView: UIImageView!
        @IBOutlet weak var imageMsg: UIImageView!
        
        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var nickname: UILabel!
        @IBOutlet weak var time: UILabel!
        
        @IBOutlet weak var spinner: UIActivityIndicatorView?
        
        @IBOutlet weak var retry: UIButton?
        var originalFrame = CGRect()
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
        
        func updateMessageCell (by message: MessageItem, name:String, avatar:Data?, isGroup:Bool) {
                cellMsg = message
                msgBackgroundView.layer.cornerRadius = 8
                msgBackgroundView.clipsToBounds = true
                let from = message.from
                let img = message.payload as? imgMsg
                imageMsg.image = UIImage(data: img?.content ?? Data())//TODO::
                imageMsg.contentMode = .scaleAspectFill
                imageMsg.clipsToBounds = true
                
                self.show(imageView: imageMsg)
  
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
                        PopulatePeerCell(nickname:self.nickname,
                                         avatarBtn: self.avatar,
                                         from: from, name: name, avatar: avatar, isGroup: isGroup)
                }
                
                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }
}

extension ImageTableViewCell{

        func show(imageView: UIImageView) {
                imageView.isUserInteractionEnabled = true

                let tap = UITapGestureRecognizer(target: self, action: #selector(showBigImage))
                imageView.addGestureRecognizer(tap)
        }
   
        @objc private func showBigImage(sender: UITapGestureRecognizer) {
             
                guard let window = getKeyWindow() else {
                        return
                }
                
                guard let image  = imageMsg.image else {
                        return
                }

                window.endEditing(true)

                originalFrame = CGRect()
                let oldFrame = imageMsg.convert(imageMsg.bounds, from: window)
                let backgroundView = UIView(frame: UIScreen.main.bounds)
                backgroundView.backgroundColor = UIColor.black
                backgroundView.alpha = 0.0

                originalFrame = oldFrame
                                let newImageV = UIImageView(frame: oldFrame)
                newImageV.contentMode = .scaleAspectFit
                newImageV.image = image
                
                
                backgroundView.addSubview(newImageV)
                window.addSubview(backgroundView)
                

                UIView.animate(withDuration: showBigDuration) {
                        let width = UIScreen.main.bounds.size.width
                        let height = image.size.height * width / image.size.width
                        let y = (UIScreen.main.bounds.size.height - image.size.height * width / image.size.width) * 0.5
                        newImageV.frame = CGRect(x: 0, y: y, width: width, height: height)
                        backgroundView.alpha = 1
                }
                let tap2 = UITapGestureRecognizer(target: self, action: #selector(ImageTableViewCell.showOriginal(sender:)))
                backgroundView.addGestureRecognizer(tap2)

                let longTap = UILongPressGestureRecognizer(target: self, action:    #selector(ImageTableViewCell.longPress(sender:)))
                backgroundView.addGestureRecognizer(longTap)
                
                
                guard let imgMessage = self.cellMsg?.payload as? imgMsg else{
                        return
                }
                
                guard !imgMessage.has.isEmpty else{
                        return
                }
                self.showIndicator(parentView:newImageV, withTitle: "", and: "")
                ServiceDelegate.workQueue.async {
                        guard let d = ServiceDelegate.LoadDataByHash(has: imgMessage.has, key: imgMessage.key) else{
                                DispatchQueue.main.async {
                                        MBProgressHUD.hide(for: newImageV, animated: true)
                                }
                                return
                        }
                        DispatchQueue.main.async {
                                MBProgressHUD.hide(for: newImageV, animated: true)
                                newImageV.image = UIImage(data: d)
                        }
                }
        }

        @objc private func longPress(sender: UILongPressGestureRecognizer) {
                guard let backgroundView = sender.view else {
                        return
                }
                guard let imgView = backgroundView.subviews.first as? UIImageView else {
                        return
                }
                
                let keyWindow = getKeyWindow()
                let alert = UIAlertController(title: "Choose opertion".locStr, message: nil, preferredStyle: .actionSheet)
                let action = UIAlertAction(title: "Save to album".locStr, style: .default) { (_) in
                        UIImageWriteToSavedPhotosAlbum(imgView.image!, nil, nil, nil)
                        //TODO::show tips
                        keyWindow?.rootViewController?.toastMessage(title: "Save success".locStr)
                }
                let cancel = UIAlertAction(title: "Cancel".locStr, style: .cancel, handler: nil)
                alert.addAction(action)
                alert.addAction(cancel)

                guard let window = keyWindow?.rootViewController else {
                        return
                }
                window.present(alert, animated: true, completion: nil)
        }
        
        @objc private func showOriginal(sender: UITapGestureRecognizer) {
                guard let backgroundView = sender.view else {
                        return
                }

                guard let imageV = backgroundView.subviews.first else {
                        return
                }

                UIView.animate(withDuration: showOriginalDuration, animations: {
                        imageV.frame = self.originalFrame
                        backgroundView.alpha = 0.0
                }) { finished in
                        backgroundView.removeFromSuperview()
                }
        }
        func showIndicator(parentView:UIView, withTitle title: String, and Description:String) {DispatchQueue.main.async {
                let Indicator = MBProgressHUD.showAdded(to: parentView, animated: true)
                Indicator.label.text = title
                Indicator.isUserInteractionEnabled = false
                Indicator.detailsLabel.text = Description
                Indicator.show(animated: true)
        }}
}
