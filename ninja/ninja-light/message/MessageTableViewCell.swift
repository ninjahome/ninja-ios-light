//
//  MessageTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/4/29.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var msgBackgroundView: UIView!
    @IBOutlet weak var msgLabel: UILabel!
    
    var trailingConstrain: NSLayoutConstraint!
    var leadingConstrain:NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        msgLabel.text = nil
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
        
        msgLabel.text = message.payload
        if message.isOut {
            msgBackgroundView.backgroundColor = .white
            msgBackgroundView.layer.borderWidth = 1
            msgBackgroundView.layer.borderColor = UIColor(displayP3Red: 231/255.0, green: 231/255.0, blue: 231/255.0, alpha: 1.0).cgColor
            trailingConstrain.isActive = true
//            msgLabel.textAlignment = .right
        } else {
            msgBackgroundView.backgroundColor = UIColor(displayP3Red: 238/255.0, green: 248/255.0, blue: 247/255.0, alpha: 1.0)
            leadingConstrain.isActive = true
//            msgLabel.textAlignment = .left
        }
    }

}
