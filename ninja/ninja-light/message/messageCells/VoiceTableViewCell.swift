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
    
    var trailingConstrain: NSLayoutConstraint!
    var leadingConstrain:NSLayoutConstraint!
    
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
        leadingConstrain.isActive = false
        trailingConstrain.isActive = false
    }

    
    func updateMessageCell (by message: MessageItem) {
        msgBackgroundView.layer.cornerRadius = 8
        msgBackgroundView.clipsToBounds = true
        
        trailingConstrain = msgBackgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        leadingConstrain = msgBackgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20)
        
        let voice = message.payload as! audioMsg
        setBtn(isOut: message.isOut, data: voice.content, long: voice.duration)
        self.isOut = message.isOut
        self.long = voice.duration
        //message bubble
        if message.isOut {
            let img = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
                msgBackgroundView.image = img
            trailingConstrain.isActive = true
        } else {
            let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
            msgBackgroundView.image = img
            leadingConstrain.isActive = true
        }
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
    
    fileprivate func filpImageH(_ data: UIImage) -> UIImage {
        let flipImageOrientation = (data.imageOrientation.rawValue + 4) % 8
        let flipImage =  UIImage(cgImage:data.cgImage!,
            scale:data.scale,
            orientation:UIImage.Orientation(rawValue: flipImageOrientation)!
        )
        return flipImage
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

//
//    private func setup(_ flip:Bool) {
//            DispatchQueue.global().async {
//                var arr = Array<UIImage>.init()
//                for e in 0...20 {
//                    let str = "voice_000" + String.init(format: "%02d", e)
//                    let path = Bundle.main.path(forResource: str, ofType: nil)
//                    if let path = path {
//                        if let image = UIImage.init(named: path) {
//                            if flip {
//                                let flipimg = self.filpImageH(image)
//                                arr.append(flipimg)
//                            } else {
//                                arr.append(image)
//                            }
//
//                        }
//                    }
//                }
//                DispatchQueue.main.async {
//                    let imageView = UIImageView()
//
//                    self.addSubview(imageView)
//
//                    imageView.contentMode = .scaleAspectFill
//                    imageView.clipsToBounds = true
//                    imageView.animationImages = arr
////                    imageView.animationDuration = self.aniamtionTime
//                    imageView.animationDuration = 2
//
//                    imageView.animationRepeatCount = 1
//                    imageView.startAnimating()
////                    self.gifView = imageView
////                    self.playBtn.imageView = imageView
//                }
//            }
//        }
//

}
