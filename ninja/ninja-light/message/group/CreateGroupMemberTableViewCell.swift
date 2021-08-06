//
//  CreateCroupMemberTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/1.
//

import UIKit

protocol CellClickDelegate {
    func addDidClick(_ idx: Int)
    func delDidClick(_ idx: Int)
}

class CreateGroupMemberTableViewCell: UITableViewCell {
    
    @IBOutlet weak var avatar: UIButton!
    @IBOutlet weak var nickName: UILabel!
    
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    
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

    func initWith(details:ContactItem, idx: Int) {
        self.index = idx
        
        let avaName = ContactItem.GetAvatarText(by: details.uid!)
        let avaHex = ContactItem.GetAvatarColor(by: details.uid!)
        
        self.avatar.setTitle(avaName, for: .normal)
        self.avatar.backgroundColor = UIColor.init(hex: avaHex)
        
        self.nickName.text = details.nickName
    }
    
    @IBAction func addToGroupList(_ sender: UIButton) {
        selectBtn.setImage(UIImage(named: "pick_icon"), for: .normal)
        deleteBtn.isHidden = false
        
        if let idx = index {
            self.cellDelegate?.addDidClick(idx)
        }
        
    }
    
    @IBAction func deleteFromGroupList(_ sender: UIButton) {
        selectBtn.setImage(UIImage(named: "+_icon-1"), for: .normal)
        deleteBtn.isHidden = true
        
        if let idx = index {
            self.cellDelegate?.delDidClick(idx)
        }
        
    }
    
}
