//
//  KeepDaysTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/3/4.
//

import UIKit

class KeepDaysTableViewCell: UITableViewCell {
        @IBOutlet weak var keepDay: UILabel!
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
                self.selectionStyle = .none
        }
        
        func initCell(days: Int) {
                keepDay.text = String(days)
        }
}
