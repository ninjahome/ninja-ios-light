//
//  CreateGroupViewController.swift
//  immeta
//
//  Created by ribencong on 2021/7/30.
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
        var isInAddingMode: Bool = false
        var isDelMember: Bool = false
        var groupItem: GroupItem = GroupItem.init()
        
        var notiMemberChange: NotiGroupChange?
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                if isInAddingMode {
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
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(groupDeleted(notification:)),
                                                       name: NotifyGroupDeleteChanged,
                                                       object: nil)
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        
        @objc func groupDeleted(notification: NSNotification) {
                guard isInAddingMode, let gid = notification.object as? String, groupItem.gid == gid else{
                        return
                }
                DispatchQueue.main.async {
                        self.navigationController?.popToRootViewController(animated: true)
                }
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
                if isInAddingMode {
                        
                        contacts.removeAll { cont in
                                let freeUser = !cont.isVIP()
                                if freeUser{
                                        invalidContact.append(cont)
                                        return true
                                }
                                return groupItem.memberIds .contains(cont.peerID) || freeUser
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
                
                if isInAddingMode {
                        self.AddMember()
                        
                } else {
                        var groupIds: [String] = []
                        guard selectedIndexs.count >= 2 else{
                                self.toastMessage(title: "Too less member".locStr)
                                return
                        }
                        
                        for i in selectedIndexs {
                                groupIds.append(validContactArr[i].peerID)
                        }
                        
                        showInputDialog(title: "Set group name".locStr, message: "", textPlaceholder: "", actionText: "Confirm".locStr, cancelText: "Cancel".locStr) { cancleAction in
                                return
                        } actionHandler: { text in
                                self.CreateGroup(member: groupIds, groupName: text ?? "")
                        }
                }
        }
        
        fileprivate func AddMember() {
                self.showIndicator(withTitle: "", and: "updating group".locStr)
                
                ServiceDelegate.workQueue.async {
                       
                        var newIds: [String] = []
                        for i in self.selectedIndexs {
                                newIds.append(self.validContactArr[i].peerID)
                        }

                        if let err = GroupItem.AddMemberToGroup(group: self.groupItem, newIds: newIds) {
                                self.toastMessage(title: "\(err.localizedDescription ?? "Add member failed".locStr)")
                                self.hideIndicator()
                                return
                        }
                        self.hideIndicator()
                        self.notiMemberChange?(self.groupItem)
                }
                
        }
        
        fileprivate func CreateGroup(member: [String], groupName: String) {
                
                self.showIndicator(withTitle: "", and: "creating group".locStr)
                
                ServiceDelegate.workQueue.async {
                        
                        do {
                                self.groupItem = try GroupItem.NewGroup(ids: member,
                                                                        groupName: groupName)
                                
                        }catch let err{
                                self.hideIndicator()
                                self.toastMessage(title: "\(err.localizedDescription)")
                                return
                        }
                        
                        DispatchQueue.main.async {
                                self.hideIndicator()
                                NotificationCenter.default.post(name:NotifyGroupCreated,
                                                                object: self.groupItem.gid, userInfo:nil)
                                let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                                vc.peerUid = self.groupItem.gid
                                vc.IS_GROUP = true
                                self.navigationController?.pushViewController(vc, animated: true)
                        }
                }
        }
        func enableOrDisableCompleteBtn(number: Int) {
                finishBtn.setTitle("完成(\(number))", for: .normal)
                if setEnable {
                        finishBtn.backgroundColor = UIColor(hex: "39BC3B")
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
                return "非会员无法加入"
        }
}

extension GroupMemberViewController : CellClickDelegate {
        
        func addDidClick(_ idx: Int) -> Bool{
                
                if selectedIndexs.count > MaxMembersInGroup{
                        self.toastMessage(title: "More than 50".locStr,duration: 1)
                        return false
                }
                
                if !selectedIndexs.contains(idx) {
                        selectedIndexs.append(idx)
                }
                
                if isInAddingMode {
                        if selectedIndexs.count > 0 {
                                self.setEnable = true
                        }
                } else {
                        if selectedIndexs.count > 1 {
                                self.setEnable = true
                        }
                }
                
                enableOrDisableCompleteBtn(number: selectedIndexs.count)
                
                print("------>>>selected list \(selectedIndexs)")
                
                return true
        }
        
        func delDidClick(_ idx: Int) {
                
                if let existedIdx = selectedIndexs.firstIndex(of: idx) {
                        selectedIndexs.remove(at: existedIdx)
                }
                
                if isInAddingMode {
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
                self.showIndicator(withTitle: "", and: "loading".locStr)
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
