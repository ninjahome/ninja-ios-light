//
//  CreateCroupMemberTableViewCell.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/1.
//

import UIKit

protocol CellClickDelegate {
        func loadSelectedContact(_ idx: Int)
        func addDidClick(_ idx: Int)
        func delDidClick(_ idx: Int)
}

class GroupMemberTableViewCell: UITableViewCell {
        
        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var nickName: UILabel!
        @IBOutlet weak var vipHint: UILabel!
        
        @IBOutlet weak var reloadBtn: UIButton!
        @IBOutlet weak var selectBtn: UIButton!
        @IBOutlet weak var deleteBtn: UIButton!
        
        var cellDelegate: CellClickDelegate?
        var index: Int?
        
        override func prepareForReuse() {
                super.prepareForReuse()
                
                setSelect(selected: false)
                vipHint.isHidden = true
                selectBtn.isHidden = false
                reloadBtn.isHidden = true
                reloadBtn.isEnabled = true
        }
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }
        
        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }
        
        func initWith(details: CombineConntact, idx: Int, selected: Bool) {
                self.index = idx
                setSelect(selected: selected)
                
                self.avatar.setup(id: details.peerID, avaData: details.account?.Avatar,showDetails: false)
                self.nickName.text = details.GetNickName() ?? details.peerID
                let isVip = details.isVIP()
                vipHint.isHidden = isVip
                selectBtn.isHidden = !isVip
                reloadBtn.isHidden = isVip
                self.isUserInteractionEnabled = isVip
        }
        
        func initWith(group: GroupItem, idx: Int, selected: Bool) {
                self.index = idx
                let id = group.memberIds[idx]
                setSelect(selected: selected)
                let acc = CombineConntact.cache[id]
                //TODO:: refactor
                self.nickName.text = acc?.GetNickName() ?? acc?.peerID
                self.avatar.setup(id: id, avaData: acc?.account?.Avatar)
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
        
        @IBAction func reloadAction(_ sender: UIButton) {
                guard let idx = index else{
                        return
                }
                self.cellDelegate?.loadSelectedContact(idx)
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
