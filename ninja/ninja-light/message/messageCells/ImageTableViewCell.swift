//
//  ImageTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/27.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var msgBackgroundView: UIImageView!
    @IBOutlet weak var imageMsg: UIImageView!
    
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
        //TODO:: Retry sending msg
    }
    
    func updateMessageCell (by message: MessageItem) {
        cellMsg = message
        msgBackgroundView.layer.cornerRadius = 8
        msgBackgroundView.clipsToBounds = true
        
        guard let from = message.from else {
            return
        }

        imageMsg.image = UIImage(data: message.payload as! Data)
        
        imageMsg.contentMode = .scaleAspectFill
        imageMsg.clipsToBounds = true
        
        ShowImageDetail.show(imageView: imageMsg)
        
        
//        let gesture = UITapGestureRecognizer(target: self, action: #selector(showBigPicture))
//        imageMsg.addGestureRecognizer(gesture)
//        imageMsg.isUserInteractionEnabled = true
        
        //message bubble
        if message.isOut {
            switch message.status {
            case .faild:
                spinner?.stopAnimating()
                retry?.isHidden = false
                //TODO::
            case .sending:
                spinner?.startAnimating()
            default:
                spinner?.stopAnimating()
            }
//            let img = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
//            msgBackgroundView.image = img
            
//            avatar.setTitle(Wallet.GenAvatarText(), for: .normal)
//            avatar.backgroundColor = UIColor.init(hex: Wallet.GenAvatarColor())
            avatar.type = AvatarButtonType.wallet
            avatar.avaInfo = nil
            
            nickname.text = Wallet.GenAvatarText()

        } else {
//            let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
//            msgBackgroundView.image = img
            
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

}
