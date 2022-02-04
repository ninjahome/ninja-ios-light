//
//  VoiceTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/27.
//

import UIKit

class VoiceTableViewCell: UITableViewCell {

        @IBOutlet weak var msgBackgroundView: UIImageView!
        @IBOutlet weak var playBtn: UIButton!

        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var nickname: UILabel!
        @IBOutlet weak var time: UILabel!
        @IBOutlet weak var retry: UIButton?
        @IBOutlet weak var spinner: UIActivityIndicatorView?

        var audioData:Data?
        var isOut: Bool?
        var long:Int = 2
        var curMsg:MessageItem?
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }
    
        override func prepareForReuse() {
                super.prepareForReuse()
                isOut = false
                playBtn.setImage(nil, for: .normal)
                spinner?.stopAnimating()
        }
        
        @IBAction func resendFailedMsg(_ sender: Any) {
                guard let msg = self.curMsg else{
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
        
        func updateMessageCell (by message: MessageItem, name:String, avatar:Data?) {
                self.curMsg = message
                guard let voice = message.payload as? audioMsg else {
                        return
                }
                let from = message.from
                
                setBtn(isOut: message.isOut, data: voice.content, long: voice.duration)
                self.isOut = message.isOut
                self.long = voice.duration
                
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

                        let img = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
                        msgBackgroundView.image = img
                        self.avatar.setupSelf()

                } else {
                        let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
                        msgBackgroundView.image = img
                        nickname.text = name
                        self.avatar.setup(id: from, avaData: avatar)
                }
                
                time.text = formatMsgTimeStamp(by: message.timeStamp)
        }
        
        
        func setBtn(isOut: Bool, data: Data, long: Int) {
                playBtn.backgroundColor = .clear
                let rawImg = UIImage(named: "voice_00009")!
                let flipImgH = filpImageH(rawImg)

                playBtn.setTitle("\(long)", for: .normal)

                let space = 20*long/60 + 20

                if isOut {
                        playBtn.imagePosition(at: .right, space: CGFloat(space))
                        playBtn.setImage(flipImgH, for: .normal)
                } else {
                        playBtn.imagePosition(at: .left, space: CGFloat(space))
                        playBtn.setImage(rawImg, for: .normal)
                }

                self.audioData = data
                playBtn.addTarget(self, action: #selector(playAudioBtnAction), for: .touchUpInside)
                self.msgBackgroundView.addSubview(playBtn)
        }
    
        @objc func playAudioBtnAction() {
                guard let data = self.audioData, data.count > 0 else{
                        print("------>>>invalid audio data")
                        return
                }
                
                AudioPlayManager.shared.playMusic(rawData: data)

                let time = TimeInterval(self.long)
                let imgs = getFilpAnimatedImg()
                let rimg = UIImage.animatedImage(with: imgs, duration: 2)
                let img = UIImage.animatedImageNamed("voice_0000", duration: 2)!
                if self.isOut! {
                        self.playBtn.setImage(rimg, for: .normal)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+time) {
                                let rawImg = UIImage(named: "voice_00009")!
                                let flipImgH = self.filpImageH(rawImg)
                                self.playBtn.setImage(flipImgH, for: .normal)
                        }
                } else {
                        self.playBtn.setImage(img, for: .normal)
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+time) {
                                let rawImg = UIImage(named: "voice_00009")!
                                self.playBtn.setImage(rawImg, for: .normal)
                        }
                }
        }
    
        fileprivate func getFilpAnimatedImg() -> [UIImage] {
                var imgs:[UIImage] = []
                for x in 0...9 {
                        let name = "voice_0000" + String(x)
                        let img = self.filpImageH(UIImage(named: name)!)
                        imgs.append(img)
                }
                return imgs
        }
    
    
        fileprivate func filpImageH(_ data: UIImage) -> UIImage {
                let flipImageOrientation = (data.imageOrientation.rawValue + 4) % 8
                let flipImage =  UIImage(cgImage:data.cgImage!,
                                         scale:data.scale,
                                         orientation:UIImage.Orientation(rawValue: flipImageOrientation)!)
                return flipImage
        }

}
