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
    
    var trailingConstrain: NSLayoutConstraint!
    var leadingConstrain:NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        leadingConstrain.isActive = false
        trailingConstrain.isActive = false
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func updateMessageCell (by message: MessageItem) {
        msgBackgroundView.layer.cornerRadius = 8
        msgBackgroundView.clipsToBounds = true
        
        trailingConstrain = msgBackgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -20)
        leadingConstrain = msgBackgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 20)
        
        imageMsg.image = UIImage(data: message.payload as! Data)
        
        imageMsg.contentMode = .scaleAspectFill
        imageMsg.clipsToBounds = true
        
        ShowImageDetail.show(imageView: imageMsg)
        
//        let gesture = UITapGestureRecognizer(target: self, action: #selector(showBigPicture))
//        imageMsg.addGestureRecognizer(gesture)
//        imageMsg.isUserInteractionEnabled = true
        
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
//
//    @objc func showBigPicture() {
//        print("show big picture")
//
//        ShowImageDetail.show(imageView: imageMsg)
//    }

}
