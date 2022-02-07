//
//  GroupDetailViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/17.
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
                        self.toastMessage(title: "invalid group meta")
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
                        self.toastMessage(title: "invalid group data", duration: 1.2)
                        return
                }
                guard let vc = instantiateViewController(vcID: "AddGrpMemberVC") as? GroupMemberViewController else{
                        self.toastMessage(title: "invalid target")
                        return
                }
                
                vc.isInAddingMode = true
                vc.groupItem = grpData
                
                vc.notiMemberChange = { newGroupInfo in
                        self.groupData = newGroupInfo
                        DispatchQueue.main.async {
                                self.navigationController?.popViewController(animated: true)
                                NotificationCenter.default.post(name:NotifyGroupChanged,
                                                                object: newGroupInfo.gid, userInfo:nil)
                        }
                }
                
                self.navigationController?.pushViewController(vc, animated: true)
        }
        
        @IBAction func copyGroupID(_ sender: UIButton) {
                UIPasteboard.general.string = groupID
                self.toastMessage(title: "copy success", duration: 1)
        }
        
        @IBAction func kickMemberBtn(_ sender: UIButton) {
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                
                self.performSegue(withIdentifier: "KickMemberSeg", sender: self)
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
                        let vc: DeleteMemberController = segue.destination as! DeleteMemberController
                        vc.groupItem = groupData
                        vc.existMember = groupData?.memberIds ?? []
                        
                        vc.notiMemberChange = { newGroupInfo in
                                self.groupData = newGroupInfo
                                self.collectionView.reloadData()
                        }
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
                c.initApperance(id: id, isMember: id != groupData.leader)
                
                return cell
        }
}

extension GroupDetailViewController{
        
        @IBAction func kickMemberViewTap(_ gesture: UITapGestureRecognizer) {
                if !self.leaderManagerd{
                        self.toastMessage(title: "only leader valid")
                        return
                }
                self.performSegue(withIdentifier: "KickMemberSeg", sender: self)
        }
        
        @IBAction func updateGroupNameViewTap(_ gesture: UITapGestureRecognizer) {
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                
                self.showInputDialog(title: "New Group Name", message: "", textPlaceholder: "Group Name", actionText: "OK", cancelText: "Cacel", cancelHandler: nil) { text in
                        guard let newName = text else{
                                self.toastMessage(title: "invalid new group name", duration: 2)
                                return
                        }
                        ServiceDelegate.workQueue.async {
                                let err = GroupItem.updateGroupName(group:self.groupData, newName:newName)
                                if let e = err{
                                        self.toastMessage(title: "\(e.localizedDescription)")
                                        return
                                }
                                
                                NotificationCenter.default.post(name:NotifyGroupChanged,
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
                self.ShowYesOrNo(msg: "You're owner and group will be dissmiessed",No: nil){
                        self.showIndicator(withTitle: "", and: "deleting group")
                        ServiceDelegate.workQueue.async {
                                defer{
                                        self.hideIndicator()
                                }
                                if let err = GroupItem.DismissGroup(gid:self.groupID){
                                        self.toastMessage(title: "\(err.localizedDescription!)")
                                        return
                                }
                                
                                DispatchQueue.main.async {
                                        self.dismiss(animated: true)
                                        self.navigationController?.popToRootViewController(animated: true)
                                        NotificationCenter.default.post(name:NotifyGroupChanged,
                                                                        object: self.groupID, userInfo:nil)
                                }
                        }
                }
                
        }
        
        private func quitFromGroup(){
                
        }
}
