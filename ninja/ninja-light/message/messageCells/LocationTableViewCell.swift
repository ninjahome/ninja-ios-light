//
//  LocationTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/27.
//

import UIKit

class LocationTableViewCell: UITableViewCell {
    @IBOutlet weak var msgBackgroundView: UIImageView!
    
    @IBOutlet weak var locationStr: UILabel!
    
    var trailingConstrain: NSLayoutConstraint!
    var leadingConstrain:NSLayoutConstraint!
    
    @IBOutlet weak var miniMapTrailing: NSLayoutConstraint!
    @IBOutlet weak var miniMapLeading: NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        miniMapTrailing.constant = 0
        miniMapLeading.constant = 0
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
        
        if let localMsg = message.payload as? locationMsg {
            print("*****LOCATION message.payload\(localMsg.la).\(localMsg.lo)。\(localMsg.str)")
            locationStr.text = localMsg.str
        }
        
        //message bubble
        if message.isOut {

            let img = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
                msgBackgroundView.image = img
            trailingConstrain.isActive = true
            miniMapTrailing.constant = 8
            
        } else {
            let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 12, bottom: 10, right: 12), resizingMode: .stretch)
            msgBackgroundView.image = img
            leadingConstrain.isActive = true
            miniMapLeading.constant = 8
            
        }
    }


}
