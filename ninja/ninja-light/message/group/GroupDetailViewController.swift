//
//  GroupDetailViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/17.
//

import UIKit

class GroupDetailViewController: UIViewController {

        @IBOutlet weak var collectionView: UICollectionView!
        @IBOutlet weak var deleteMemberBtn: UIButton!
        @IBOutlet weak var viewTitle: UINavigationItem!
        
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
        }
        
        private func setupView(){
                if let n = groupData?.groupName, !n.isEmpty{
                        groupName = n
                }else{
                        groupName = groupID
                }
                
                deleteMemberBtn.isEnabled = self.leaderManagerd
                viewTitle.title = groupName
        }
        
        @IBAction func addMemberBtn(_ sender: UIButton) {
                let vc = instantiateViewController(vcID: "AddGrpMemberVC") as! GroupMemberViewController
                vc.isAddMember = true
                vc.groupItem = groupData!
                vc.existMember = groupData!.memberIds

                vc.notiMemberChange = { newGroupInfo in
                        self.groupData = newGroupInfo
                        DispatchQueue.main.async {
                                self.setupView()
                                self.collectionView.reloadData()
                        }
                }
                self.navigationController?.pushViewController(vc, animated: true)
        }
    
        @IBAction func kickMemberBtn(_ sender: UIButton) {
                self.performSegue(withIdentifier: "KickMemberSeg", sender: self)
        }
    
        @IBAction func quitOrDismissGroup(_ sender: UIButton) {

                if let group = groupData {
                        let err = GroupItem.QuitGroup(groupItem: group)
                        if err != nil {
                                self.toastMessage(title: "quit group error.\(String(describing: err?.localizedDescription))")
                        }
                }
                self.navigationController?.popToRootViewController(animated: true)
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
                return groupData.memberIds.count + 1
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                if indexPath.row == 0 {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddCollectionCell", for: indexPath) as! AddCollectionCell
                        return cell
                }
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCollectionCell", for: indexPath)
                guard let c = cell as? AvatarCollectionCell else{
                        return cell
                }
                let id = groupData.memberIds[indexPath.row - 1]
                c.initApperance(id: id)

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
}
