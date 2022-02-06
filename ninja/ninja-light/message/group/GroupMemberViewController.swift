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
        var validContactArr: [CombineConntact] = []
        var invalidContactArr: [CombineConntact] = []
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
                
                contactsFilter()
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(updateGroupList(notification:)),
                                                       name: NotifyGroupChanged,
                                                       object: nil)
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func updateGroupList(notification: NSNotification) {
                contactsFilter()
                DispatchQueue.main.async {
                        self.tableView.reloadData()
                }
        }
        
        fileprivate func contactsFilter(){
                var contacts = CombineConntact.CacheArray()
                var invalidContact:[CombineConntact] = []
                if isAddMember {
                        contacts.removeAll { cont in
                                existMember.contains(cont.peerID)
                        }
                } else {
                        contacts.removeAll { cont in
                                if !cont.isVIP(){
                                        invalidContact.append(cont)
                                        return true
                                }
                                return  cont.peerID == Wallet.shared.Addr
                        }
                }
                self.validContactArr = contacts
                self.invalidContactArr = invalidContact
        }
        
        @IBAction func returnBackItem(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }
        
        @IBAction func finishAction(_ sender: UIButton) {
                if !setEnable {
                        return
                }
                
                if isAddMember {
                        
                        var groupIds = groupItem.memberIds
                        var newIds: [String] = []
                        for i in selectedIndexs {
                                newIds.append(validContactArr[i].peerID)
                                groupIds.append(validContactArr[i].peerID)
                        }
                        
                        groupItem.memberIds = groupIds
                        
                        self.AddMember(newIds: newIds)
                        print("groupIds:\(groupIds)")
                        
                } else {
                        var groupIds: [CombineConntact] = []
                        guard selectedIndexs.count >= 2 else{
                                self.toastMessage(title: "too less member")
                                return
                        }
                        
                        for i in selectedIndexs {
                                groupIds.append(validContactArr[i])
                        }
                        
                        showInputDialog(title: "取个群名", message: "", textPlaceholder: "", actionText: "确定", cancelText: "暂不取名") { cancleAction in
                                self.CreateGroup(member: groupIds, groupName: "")
                        } actionHandler: { text in
                                self.CreateGroup(member: groupIds, groupName: text ?? "")
                        }
                }
        }
        
        fileprivate func AddMember(newIds: [String]) {
                
                if let err = GroupItem.AddMemberToGroup(group: self.groupItem, newIds: newIds) {
                        self.toastMessage(title: "add member to group faild.\(String(describing: err.localizedDescription))")
                        return
                }
                
                do{
                        try GroupItem.syncGroupMeta(groupItem)
                        self.notiMemberChange(groupItem)
                        self.navigationController?.popViewController(animated: true)
                        return
                        
                }catch let err {
                        self.toastMessage(title: "Save GroupItem failed[\(err.localizedDescription)]")
                }
        }
        
        fileprivate func CreateGroup(member: [CombineConntact], groupName: String) {
                
                self.showIndicator(withTitle: "", and: "creating group")
                
                ServiceDelegate.workQueue.async {
                        defer{
                                self.hideIndicator()
                        }
                        
                        let validMemIDs = CombineConntact.updateSetOfContact(ids: member)
                        if validMemIDs.count < 2{
                                self.toastMessage(title: "too less valid friend")
                                return
                        }
                        
                        do {
                                self.groupItem = try GroupItem.NewGroup(ids: validMemIDs,
                                                                        groupName: groupName)
                                
                        }catch let err{
                                self.toastMessage(title: "\(err.localizedDescription)")
                        }
                        
                        DispatchQueue.main.async {
                                let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                                vc.peerUid = self.groupItem.gid
                                vc.IS_GROUP = true
                                var vcs = self.navigationController?.viewControllers
                                _ = vcs?.popLast()
                                vcs!.append(vc)
                                self.navigationController?.setViewControllers(vcs!, animated: true)
//                                        self.navigationController?.pushViewController(vc, animated: true)
                                        NotificationCenter.default.post(name:NotifyGroupChanged,
                                                                        object: self.groupItem.gid, userInfo:nil)
                                return
                        }
                }
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
                if section == 0{
                        return validContactArr.count
                }
                return invalidContactArr.count
        }
        
        func numberOfSections(in tableView: UITableView) -> Int {
                return 2
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
                if indexPath.section == 0{
                        let cell = tableView.dequeueReusableCell(withIdentifier: "CreateGroupMemberTableViewCell", for: indexPath)
                        
                        let item:CombineConntact = validContactArr[indexPath.row]
                        
                        if let c = cell as? GroupMemberTableViewCell {
                                let selected = selectedIndexs.contains(indexPath.row)
                                c.initWith(details: item, idx: indexPath.row, selected: selected)
                                c.cellDelegate = self
                                return c
                        }
                        return cell
                }
                
                let item = invalidContactArr[indexPath.row]
                let cell = tableView.dequeueReusableCell(withIdentifier: "InvalidGroupMemberTableViewCell", for: indexPath)
                guard let c = cell as? InvalidGrpMemberTableViewCell else{
                        return cell
                }
                c.initWith(details: item, idx: indexPath.row)
                c.cellDelegate = self
                return c
        }
        func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
                guard section == 1 else{
                        return ""
                }
                return "非会员无权限"
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
                
                print("------>>>selected list \(selectedIndexs)")
        }
        
        func loadSelectedContact(_ idx:Int){
                self.showIndicator(withTitle: "", and: "loading")
                ServiceDelegate.workQueue.async{
                        defer {
                                self.hideIndicator()
                        }
                        
                        let item = self.invalidContactArr[idx]
                        guard let pid = item.contact?.uid else{
                                return
                        }
                        guard let data = CombineConntact.fetchContactFromChain(pid: pid) else{
                                return
                        }
                        guard let nonce = data.account?.Nonce  else{
                                return
                        }
                        if nonce == item.account?.Nonce{
                                return
                        }
                        
                        CombineConntact.cache[pid] = data
                        
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                        object: pid, userInfo:nil)
                        
                        if !data.isVIP(){
                                return
                        }
                        self.invalidContactArr.remove(at: idx)
                        self.validContactArr.append(data)
                        DispatchQueue.main.async {
                                self.tableView.reloadData()
                        }
                }
        }
}
