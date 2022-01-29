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
        
        @IBOutlet weak var vipHint: UILabel!
        

        override func prepareForReuse() {
                super.prepareForReuse()

                setSelect(selected: false)
                vipHint.isHidden = true
                selectBtn.isHidden = false
        }
    
        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }

        func initWith(details: ContactItem, idx: Int, selected: Bool) {
                self.index = idx
                setSelect(selected: selected)
                guard let uid = details.uid else {
                        return
                }
                self.avatar.type = AvatarButtonType.contact
                self.nickName.text = ContactItem.GetNickName(uid: uid)
                if let acc = AccountItem.GetAccount(uid) {
                        self.avatar.avaInfo = AvatarInfo.init(id: uid, avaData: acc.Avatar)
                        if Int(acc.Balance ?? 0) <= 0 {
                                vipHint.isHidden = false
                                selectBtn.isHidden = true
                                self.isUserInteractionEnabled = false
                        }
                }
        }
    
        func initWith(group: GroupItem, idx: Int, selected: Bool) {
                self.index = idx

                let id = group.memberIds[idx]
//                let nick = group.memberNicks![idx] as! String
                setSelect(selected: selected)

//                self.nickName.text = nick != "" ? nick: id

                self.avatar.type = AvatarButtonType.contact
                let acc = AccountItem.GetAccount(id)
                self.nickName.text = ContactItem.GetNickName(uid: id)
                self.avatar.avaInfo = AvatarInfo.init(id: id, avaData: acc?.Avatar)
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
