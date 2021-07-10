//
//  MessageTableViewCell.swift
//  ninja-light
//
//  Created by akatuki on 2021/4/29.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var msgBackgroundView: UIImageView!
    @IBOutlet weak var msgLabel: UILabel!
    
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
        msgLabel.text = message.payload as? String
        
        //message bubble
        if message.isOut {
//            let frame = msgBackgroundView.frame
//            let imgView = UIImageView.init(frame: frame)
            let img = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
                msgBackgroundView.image = img
//            msgBackgroundView.addSubview(imgView)
//            msgBackgroundView.insertSubview(imgView, at: 0)
            trailingConstrain.isActive = true
        } else {
            let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
            msgBackgroundView.image = img
            leadingConstrain.isActive = true
        }
    }

}
