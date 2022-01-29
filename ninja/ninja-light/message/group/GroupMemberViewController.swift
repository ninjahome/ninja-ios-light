//
//  CreateGroupViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/7/30.
//

import UIKit

typealias NotiGroupChange = (GroupItem) -> ()

class GroupMemberViewController: UIViewController {

        @IBOutlet weak var actTitle: UINavigationItem!
        @IBOutlet weak var tableView: UITableView!
        @IBOutlet weak var finishBtn: UIButton!

        var selectedIndexs = [Int]()
        var setEnable: Bool = false
        var contactArray: [ContactItem]?
        var isAddMember: Bool = false
        var isDelMember: Bool = false
        var existMember: [String] = []

        var groupItem: GroupItem = GroupItem.init()

        var notiMemberChange: NotiGroupChange!
    
        override func viewDidLoad() {
                super.viewDidLoad()

                if isAddMember {
                        actTitle.title = "添加新成员"
                }

                self.tableView.delegate = self
                self.tableView.dataSource = self
                self.tableView.rowHeight = 64
                self.tableView.tableFooterView = UIView()

                self.contactArray = contactsFilter()

                self.reload()
        }
    
        fileprivate func contactsFilter() -> [ContactItem] {
                var contacts = ContactItem.CacheArray()

                if isAddMember {
                        contacts.removeAll { cont in
                                existMember.contains(cont.uid!)
                        }
                } else {
                        contacts.removeAll { cont in
                                cont.uid == Wallet.shared.Addr
                        }
                }

                return contacts
        }
    
        @IBAction func returnBackItem(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }

        @IBAction func finishAction(_ sender: UIButton) {
                if !setEnable {
                        return
                }
        
                if isAddMember {
                        guard let contacts = contactArray else {
                                return
                        }

                        var groupIds = groupItem.memberIds
//                        var groupNicks = groupItem.memberNicks as! [String]
                        var newIds: [String] = []

                        for i in selectedIndexs {
                                newIds.append(contacts[i].uid!)
                                groupIds.append(contacts[i].uid!)
//                                groupNicks.append(contacts[i].alias ?? "")
                        }

                        groupItem.memberIds = groupIds
//                        groupItem.memberNicks = groupNicks as NSArray
//                        groupItem.UpdateSelfInfos()

                        self.AddMember(newIds: newIds)
                        print("groupIds:\(groupIds)")

                } else {
                        if let contacts = contactArray {
                                var groupIds: [String] = []
                                for i in selectedIndexs {
                                        groupIds.append(contacts[i].uid!)
                                }

                                showInputDialog(title: "取个群名", message: "", textPlaceholder: "", actionText: "确定", cancelText: "暂不取名") { cancleAction in
                                        self.CreateGroup(ids: groupIds, groupName: "")
                                } actionHandler: { text in
                                        self.CreateGroup(ids: groupIds, groupName: text ?? "")
                                }
                        }
                }
        }
    
        fileprivate func AddMember(newIds: [String]) {

                if let err = GroupItem.AddMemberToGroup(group: self.groupItem, newIds: newIds) {
                        self.toastMessage(title: "add member to group faild.\(String(describing: err.localizedDescription))")
                        return
                }

                guard let error = GroupItem.updateGroupMetaInDB(groupItem) else {
                        self.notiMemberChange(groupItem)
                        self.navigationController?.popViewController(animated: true)
                        return
                }

                self.toastMessage(title: "Save GroupItem failed \(String(describing: error.localizedDescription))")
        }

        fileprivate func CreateGroup(ids: [String], groupName: String) {
                guard let groupId = GroupItem.NewGroup(ids: ids, groupName: groupName) else {
                        self.toastMessage(title: "Created group failed")
                        return
                }
                let wallet = Wallet.shared.Addr!
                groupItem.gid = groupId
                groupItem.groupName = groupName
                groupItem.memberIds = ids 
//                groupItem.memberNicks = nicks as NSArray
                groupItem.owner = wallet
                groupItem.leader = wallet
                groupItem.unixTime = Int64(Date().timeIntervalSince1970)
                var allIds: [String] = ids
                allIds.append(wallet)
                if let grpImg = GroupItem.getGroupAvatar(ids: allIds) {
                        groupItem.avatar = grpImg
                }
                
                guard let err = GroupItem.updateGroupMetaInDB(groupItem) else {
                        let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                        vc.peerUid = groupItem.gid!
                        vc.groupData = groupItem
                        vc.IS_GROUP = true
                        self.navigationController?.pushViewController(vc, animated: true)
                        return
                }
                self.toastMessage(title: "Save GroupItem failed \(String(describing: err.localizedDescription))")
        }
    
        private func reload() {
                self.tableView.reloadData()
        }
        
        func enableOrDisableCompleteBtn(number: Int) {
                finishBtn.setTitle("完成(\(number))", for: .normal)

                if setEnable {
                        finishBtn.backgroundColor = UIColor(hex: "3B877F")
                } else {
                        finishBtn.backgroundColor = UIColor(hex: "A9A9AE")
                }
        }

}

extension GroupMemberViewController: UITableViewDelegate, UITableViewDataSource {
    
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                guard let contacts = contactArray else {
                        return 0
                }
                return contacts.count
        }
    
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CreateGroupMemberTableViewCell", for: indexPath)

                guard let contacts = contactArray else {
                        return cell
                }

                if let c = cell as? GroupMemberTableViewCell {
                        let item = contacts[indexPath.row]
                        let selected = selectedIndexs.contains(indexPath.row)

                        c.initWith(details: item, idx: indexPath.row, selected: selected)
                        c.cellDelegate = self

                        return c
                }
                return cell
        }
}

extension GroupMemberViewController : CellClickDelegate {
    
        func addDidClick(_ idx: Int) {

                if !selectedIndexs.contains(idx) {
                        selectedIndexs.append(idx)
                }

                if isAddMember {
                        if selectedIndexs.count > 0 {
                                self.setEnable = true
                        }
                } else {
                        if selectedIndexs.count > 1 {
                                self.setEnable = true
                        }
                }

                enableOrDisableCompleteBtn(number: selectedIndexs.count)

                print("selected list \(selectedIndexs)")
        }
    
        func delDidClick(_ idx: Int) {

                if let existedIdx = selectedIndexs.firstIndex(of: idx) {
                        selectedIndexs.remove(at: existedIdx)
                }

                if isAddMember {
                        if selectedIndexs.count < 1 {
                                self.setEnable = false
                        }
                } else {
                        if selectedIndexs.count < 2 {
                                self.setEnable = false
                        }
                }

                enableOrDisableCompleteBtn(number: selectedIndexs.count)

                print("selected list \(selectedIndexs)")

        }

}
