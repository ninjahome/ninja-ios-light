//
//  CreateCroupMemberTableViewCell.swift
//  immeta
//
//  Created by 郭晓芙 on 2021/8/1.
//

import UIKit

protocol CellClickDelegate {
        func loadSelectedContact(_ idx: Int)
        func addDidClick(_ idx: Int)->Bool
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
                selectBtn.isHidden = false
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
        }
        
        func initWith(memberUID: String, idx: Int, selected: Bool) {
                self.index = idx
                setSelect(selected: selected)
                let (name, avatar) = ServiceDelegate.queryNickAndAvatar(pid: memberUID) { name, avatar in
                        DispatchQueue.main.async {
                                self.initCellInfo(pid: memberUID, name: name, avatar: avatar)
                        }
                }
                initCellInfo(pid: memberUID, name: name, avatar: avatar)
        }
        
        private func initCellInfo(pid:String, name:String?, avatar:Data?){
                self.nickName.text = name
                self.avatar.setup(id: pid, avaData: avatar)
        }
        
        @IBAction func addToGroupList(_ sender: UIButton) {
                guard let idx = index, self.cellDelegate?.addDidClick(idx) == true else{
                        return
                }
                setSelect(selected: true)
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
