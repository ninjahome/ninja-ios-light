//
//  DeleteMemberController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/20.
//

import UIKit

class DeleteMemberController: UIViewController {
        
        @IBOutlet weak var tableView: UITableView!
        @IBOutlet weak var finishBtn: UIButton!
        
        private var selectedIndexs = [Int]()
        private var setEnable: Bool = false
        
        private var existMember: [String] = []
        var groupItem: GroupItem!
        var notiMemberChange: NotiGroupChange!
        
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.tableView.delegate = self
                self.tableView.dataSource = self
                self.tableView.rowHeight = 64
                self.tableView.tableFooterView = UIView()
                guard var mem = self.groupItem?.memberIds else{
                        print("------>>> invalid data to populate this view")
                        return
                }
                mem.removeAll { uid in
                        uid == Wallet.shared.Addr!
                }
                self.existMember = mem
        }
        
        @IBAction func returnBackItem(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }
        
        @IBAction func deleteMemberAction(_ sender: UIButton) {
                if !setEnable {
                        return
                }
                
                
                let groupIds = groupItem?.memberIds
                //        var groupNicks = groupItem?.memberNicks as! [String]
                var delIds: [String] = []
                
                for i in selectedIndexs {
                        delIds.append(existMember[i] )
                        groupItem?.memberInfos.removeValue(forKey: existMember[i] )
                }
                
                let ids = groupItem?.memberInfos.map({ (k: String, v: String) in
                        return k
                })
                
                if let err = GroupItem.KickOutUser(group: groupItem!, kickUserId: delIds) {
                        
                        self.toastMessage(title: "kick faild: \(String(describing: err.localizedDescription))")
                        return
                }
                
                groupItem?.memberIds = ids ?? []
                self.notiMemberChange(groupItem!)
                self.navigationController?.popViewController(animated: true)
                
        }
        
        func enableOrDisableCompleteBtn(number: Int) {
                finishBtn.setTitle("完成(\(number))", for: .normal)
                
                if setEnable {
                        finishBtn.backgroundColor = UIColor(hex: "26253C")
                } else {
                        finishBtn.backgroundColor = UIColor(hex: "A9A9AE")
                }
        }
        
        
}

extension DeleteMemberController: UITableViewDataSource, UITableViewDelegate {
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return existMember.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "CreateGroupMemberTableViewCell", for: indexPath)
                
                guard  let c = cell as? GroupMemberTableViewCell else{
                        return cell
                }
                
                let selected = selectedIndexs.contains(indexPath.row)
                c.initWith(memberUID: self.existMember[indexPath.row],
                           idx: indexPath.row,
                           selected: selected)
                c.cellDelegate = self
                return c
        }
}

extension DeleteMemberController: CellClickDelegate {
        func loadSelectedContact(_ idx: Int) {
                return
        }
        
        func addDidClick(_ idx: Int) ->Bool{
                if selectedIndexs.count > MaxMembersInGroup{
                        self.toastMessage(title: "more than 50 people", duration: 1)
                        return false
                }
                if !selectedIndexs.contains(idx) {
                        selectedIndexs.append(idx)
                }
                
                if selectedIndexs.count > 0 {
                        self.setEnable = true
                }
                
                enableOrDisableCompleteBtn(number: selectedIndexs.count)
                
                print("------>>>selected list \(selectedIndexs)")
                return true
        }
        
        func delDidClick(_ idx: Int) {
                if let existedIdx = selectedIndexs.firstIndex(of: idx) {
                        selectedIndexs.remove(at: existedIdx)
                }
                
                if selectedIndexs.count < 1 {
                        self.setEnable = false
                }
                
                enableOrDisableCompleteBtn(number: selectedIndexs.count)
                
                print("------>>>selected list \(selectedIndexs)")
        }
}
