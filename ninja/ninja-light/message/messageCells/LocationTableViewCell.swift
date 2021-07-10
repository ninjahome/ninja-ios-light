//
//  LocationTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/27.
//

import UIKit

class LocationTableViewCell: UITableViewCell {
    
    
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

}
