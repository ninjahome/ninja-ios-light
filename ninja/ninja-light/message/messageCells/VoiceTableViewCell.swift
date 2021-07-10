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
        
//        print("audio duration\(long)")
        let rawImg = UIImage(named: "voice_00019")!
        
        playBtn.setTitle("\(long)", for: .normal)
        //voice message bubble
        if isOut {
            let flipImgH = filpImageH(rawImg)
            playBtn.imagePosition(at: .right, space: 18)
            playBtn.setImage(flipImgH, for: .normal)

        } else {
            playBtn.imagePosition(at: .left, space: 18)
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
    
    @objc func playAudioBtnAction() {
        if let data = self.audioData {
            AudioPlayManager.sharedInstance.playMusic(file: data)
            
//            let time = TimeInterval(self.long)
//            let img = UIImage.animatedImageNamed("voice_0000", duration: time)!
//            if self.isOut! {
//                let rimg = self.filpImageH(img)
//                self.playBtn.setImage(rimg, for: .normal)
//            } else {
//                self.playBtn.setImage(img, for: .normal)
//            }
            
        }
    }

    
    private func setup(_ flip:Bool) {
            DispatchQueue.global().async {
                var arr = Array<UIImage>.init()
                for e in 0...20 {
                    let str = "voice_000" + String.init(format: "%02d", e)
                    let path = Bundle.main.path(forResource: str, ofType: nil)
                    if let path = path {
                        if let image = UIImage.init(named: path) {
                            if flip {
                                let flipimg = self.filpImageH(image)
                                arr.append(flipimg)
                            } else {
                                arr.append(image)
                            }

                        }
                    }
                }
                DispatchQueue.main.async {
                    let imageView = UIImageView()
                    
                    self.addSubview(imageView)
                    
                    imageView.contentMode = .scaleAspectFill
                    imageView.clipsToBounds = true
                    imageView.animationImages = arr
//                    imageView.animationDuration = self.aniamtionTime
                    imageView.animationDuration = 2
                    
                    imageView.animationRepeatCount = 1
                    imageView.startAnimating()
//                    self.gifView = imageView
//                    self.playBtn.imageView = imageView
                }
            }
        }


}
