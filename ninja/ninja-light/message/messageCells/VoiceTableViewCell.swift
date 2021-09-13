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

    
    var audioData:Data?
    var isOut: Bool?
    var long:Int = 2
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isOut = false
        playBtn.setImage(nil, for: .normal)
    }
    
    func updateMessageCell (by message: MessageItem) {
        
        guard let voice = message.payload as? audioMsg else {
            return
        }
        
        guard let from = message.from else {
            return
        }

        setBtn(isOut: message.isOut, data: voice.content, long: voice.duration)
        self.isOut = message.isOut
        self.long = voice.duration
        //message bubble
        if message.isOut {
            let img = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
            msgBackgroundView.image = img
            
            avatar.type = AvatarButtonType.wallet
            avatar.avaInfo = nil
//            avatar.setTitle(Wallet.GenAvatarText(), for: .normal)
//            avatar.backgroundColor = UIColor.init(hex: Wallet.GenAvatarColor())
            
            nickname.text = Wallet.GenAvatarText()

        } else {
            let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
            msgBackgroundView.image = img
            
//            let avaName = ContactItem.GetAvatarText(by: from)
//            avatar.setTitle(ContactItem.GetAvatarText(by: avaName), for: .normal)
//            let hex = ContactItem.GetAvatarColor(by: from)
//            avatar.backgroundColor = UIColor.init(hex: hex)
            avatar.type = AvatarButtonType.contact
            avatar.avaInfo = AvatarInfo.init(id: from)
            
            let contactData = ContactItem.cache[from]
            nickname.text = contactData?.nickName ?? ContactItem.GetAvatarText(by: from)

        }
        
        time.text = formatTimeStamp(by: message.timeStamp)
        
        
    }
    
    func setBtn(isOut: Bool, data: Data, long: Int) {
        playBtn.backgroundColor = .clear
        let rawImg = UIImage(named: "voice_00009")!
        let flipImgH = filpImageH(rawImg)
    
        playBtn.setTitle("\(long)", for: .normal)
        //voice message bubble
//        let space = 20*long/60 + 20
        let space = 20
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
        if let data = self.audioData {
            AudioPlayManager.sharedInstance.playMusic(file: data)
            
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
            orientation:UIImage.Orientation(rawValue: flipImageOrientation)!
        )
        return flipImage
    }



}
