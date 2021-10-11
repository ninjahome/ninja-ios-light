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

class GroupMemberTableViewCell: UITableViewCell {
    
    @IBOutlet weak var avatar: AvatarButton!
    @IBOutlet weak var nickName: UILabel!
    
    @IBOutlet weak var selectBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    
    var cellDelegate: CellClickDelegate?
    var index: Int?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        setSelect(selected: false)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }

    func initWith(details: ContactItem, idx: Int, selected: Bool) {
        self.index = idx
        self.nickName.text = details.nickName
        
        setSelect(selected: selected)
        
        guard let uid = details.uid else {
            return
        }
        
        self.avatar.type = AvatarButtonType.contact
        self.avatar.avaInfo = AvatarInfo.init(id: uid)

    }
    
    func initWith(group: GroupItem, idx: Int, selected: Bool) {
        self.index = idx
        
        let id = group.memberIds![idx] as! String
        let nick = group.memberNicks![idx] as! String
        
        setSelect(selected: selected)
        
        self.nickName.text = nick != "" ? nick: id
        
        self.avatar.type = AvatarButtonType.contact
        self.avatar.avaInfo = AvatarInfo.init(id: id)
        
    }
    
    @IBAction func addToGroupList(_ sender: UIButton) {
        setSelect(selected: true)
        
        if let idx = index {
            self.cellDelegate?.addDidClick(idx)
        }
        
    }
    
    @IBAction func deleteFromGroupList(_ sender: UIButton) {
        setSelect(selected: false)
        
        if let idx = index {
            self.cellDelegate?.delDidClick(idx)
        }
    }
    
    fileprivate func setSelect(selected: Bool) {
        if selected {
            selectBtn.setImage(UIImage(named: "pick_icon"), for: .normal)
            deleteBtn.isHidden = false
        } else {
            selectBtn.setImage(UIImage(named: "+_icon-1"), for: .normal)
            deleteBtn.isHidden = true
        }
        
    }
    
}
