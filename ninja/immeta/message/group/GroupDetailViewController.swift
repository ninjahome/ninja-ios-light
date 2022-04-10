//
//  GroupDetailViewController.swift
//  immeta
//
//  Created by ribencong on 2021/8/17.
//

import UIKit

class GroupDetailViewController: UIViewController {
        
        @IBOutlet weak var collectionView: UICollectionView!
        @IBOutlet weak var viewTitle: UINavigationItem!
        
        @IBOutlet weak var kickMemView: UIView!
        @IBOutlet weak var changeNameView: UIView!
        @IBOutlet weak var groupNameLabel: UILabel!
        @IBOutlet weak var groupIDLabel: UILabel!
        
        @IBOutlet var vipFlagGroups: [UIImageView]!
        
        var groupID: String = ""
        var groupName:String = ""
        var groupData:GroupItem!
        var leaderManagerd:Bool = false
        
        override func viewDidLoad() {
                super.viewDidLoad()
                collectionView.delegate = self
                collectionView.dataSource = self
                guard let data = GroupItem.cache[groupID] else{
                        self.toastMessage(title: "Invalid group data".locStr)
                        self.dismiss(animated: true)
                        self.navigationController?.popToRootViewController(animated: true)
                        return//dismiss //TODO::
                }
                self.groupData = data
                self.leaderManagerd = data.leader == Wallet.shared.Addr
                setupView()
                ServiceDelegate.updateGroupInBackGround(group: data)
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(updateGroupDetails(notification:)),
                                                       name: NotifyGroupChanged,
                                                       object: nil)
        }
        
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func updateGroupDetails(notification: NSNotification) {
                DispatchQueue.main.async {
                        self.setupView()
                        self.collectionView.reloadData()
                }
        }
        private func setupView(){
                if let n = groupData?.groupName, !n.isEmpty{
                        groupName = n
                }
                kickMemView.isHidden = !self.leaderManagerd
                changeNameView.isHidden = !self.leaderManagerd
                viewTitle.title = groupName
                groupNameLabel.text = groupName
                groupIDLabel.text = groupID
                let isVip = Wallet.shared.isStillVip()
                for item in vipFlagGroups{
                        item.isHidden = isVip
                }
        }
        
        @IBAction func addMemberBtn(_ sender: UIButton) {
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                
                guard let grpData = groupData else{
                        self.toastMessage(title: "Invalid group data".locStr, duration: 1.2)
                        return
                }
                guard let vc = instantiateViewController(vcID: "AddGrpMemberVC") as? GroupMemberViewController else{
                        self.toastMessage(title: "Invalid target".locStr)
                        return
                }
                
                vc.isInAddingMode = true
                vc.groupItem = grpData
                
                vc.notiMemberChange = self.memberChnaged
                self.navigationController?.pushViewController(vc, animated: true)
        }
        
        @IBAction func copyGroupID(_ sender: UIButton) {
                UIPasteboard.general.string = groupID
                self.toastMessage(title: "Copy success".locStr, duration: 1)
        }
        
        @IBAction func quitOrDismissGroup(_ sender: UIButton) {
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                if leaderManagerd{
                        dismissGroup()
                }else{
                        quitFromGroup()
                }
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "KickMemberSeg" {
                        guard  let vc: DeleteMemberController = segue.destination as? DeleteMemberController else{
                                return
                        }
                        vc.groupItem = groupData
                        vc.notiMemberChange = self.memberChnaged
                }
        }
}

extension GroupDetailViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                if self.leaderManagerd{
                        return groupData.memberIds.count + 1
                }
                return groupData.memberIds.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                if self.leaderManagerd && indexPath.row == 0 {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddCollectionCell", for: indexPath) as! AddCollectionCell
                        return cell
                }
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCollectionCell", for: indexPath)
                guard let c = cell as? AvatarCollectionCell else{
                        return cell
                }
                var dataIdx = indexPath.row
                if self.leaderManagerd{
                        dataIdx = dataIdx - 1
                }
                let id = groupData.memberIds[dataIdx]
                c.initApperance(id: id, isLeader:  id == groupData.leader)
                return cell
        }
}

extension GroupDetailViewController{
        
        @IBAction func kickMemberViewTap(_ gesture: UITapGestureRecognizer) {
                if !self.leaderManagerd{
                        self.toastMessage(title: "Only leader valid".locStr)
                        return
                }
                
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                guard self.groupData.memberIds.count > 3 else{
                        self.ShowTips(msg: "not enough member to delete".locStr)
                        return
                }
                
                self.performSegue(withIdentifier: "KickMemberSeg", sender: self)
        }
        
        @IBAction func updateGroupNameViewTap(_ gesture: UITapGestureRecognizer) {
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                
                self.showInputDialog(title: "New Group Name".locStr,
                                     message: "",
                                     textPlaceholder: "Group Name".locStr,
                                     actionText: "OK".locStr,
                                     cancelText: "Cacel".locStr,
                                     cancelHandler: nil) { text in
                        guard let newName = text else{
                                self.toastMessage(title: "Invalid new group name".locStr, duration: 2)
                                return
                        }
                        ServiceDelegate.workQueue.async {
                                let err = GroupItem.updateGroupName(group:self.groupData, newName:newName)
                                if let e = err{
                                        self.toastMessage(title: "\(e.localizedDescription)")
                                        return
                                }
                                
                                NotificationCenter.default.post(name:NotifyGroupNameOrAvatarChanged,
                                                                object: self.groupID, userInfo:nil)
                        }
                        
                        DispatchQueue.main.async {
                                self.groupName = newName
                                self.viewTitle.title = newName
                                self.groupNameLabel.text = newName
                        }
                }
        }
        
        private func dismissGroup(){
                self.ShowYesOrNo(msg: "You're owner and group will be dissmiessed".locStr,No: nil){
                        self.showIndicator(withTitle: "", and: "deleting group".locStr)
                        ServiceDelegate.workQueue.async {
                                
                                if let err = GroupItem.DismissGroup(gid:self.groupID){
                                        self.hideIndicator()
                                        self.toastMessage(title: "\(err.localizedDescription!)")
                                        return
                                }
                                
                                self.exitGroupView()
                        }
                }
        }
        
        private func quitFromGroup(){
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                
                self.ShowYesOrNo(msg: "确认") {
                        return
                } Yes: {
                        self.showIndicator(withTitle: "Quit Group".locStr, and: "processing".locStr)
                        ServiceDelegate.workQueue.async {
                                
                                let err = GroupItem.QuitFromGroup(group:self.groupData)
                                if let e = err{
                                        self.hideIndicator()
                                        self.toastMessage(title: "\(e.localizedDescription ?? "Quit failed".locStr)")
                                        return
                                }
                                
                                self.exitGroupView()
                        }
                }               
        }
        
        private func exitGroupView(){
                DispatchQueue.main.async {
                        self.hideIndicator()
                        self.dismiss(animated: true)
                        self.navigationController?.popToRootViewController(animated: true)
                        NotificationCenter.default.post(name:NotifyGroupDeleteChanged,
                                                        object: self.groupID, userInfo:nil)
                }
        }
        
        
        
        private func memberChnaged(_ newGroupInfo:GroupItem){
                DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                        NotificationCenter.default.post(name:NotifyGroupMemberChanged,
                                                        object: newGroupInfo.gid, userInfo:nil)
                        
                        self.groupData = newGroupInfo
                        self.collectionView.reloadData()
                }
        }
}
