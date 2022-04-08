//
//  InvalidGrpMemberTableViewCell.swift
//  immeta
//
//  Created by wesley on 2022/2/5.
//

import UIKit

class InvalidGrpMemberTableViewCell: UITableViewCell {
        
        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var nickName: UILabel!
        
        var cellDelegate: CellClickDelegate?
        var index: Int?
        
        override func awakeFromNib() {
                super.awakeFromNib()
                // Initialization code
        }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
                
                // Configure the view for the selected state
        }
        
        func initWith(details: CombineConntact, idx: Int) {
                self.index = idx
                
                self.avatar.setup(id: details.peerID, avaData: details.account?.Avatar,showDetails: false)
                self.nickName.text = details.GetNickName() ?? details.peerID
        }
        
        @IBAction func reloadAction(_ sender: UIButton) {
                guard let idx = index else{
                        return
                }
                self.cellDelegate?.loadSelectedContact(idx)
        }
}
