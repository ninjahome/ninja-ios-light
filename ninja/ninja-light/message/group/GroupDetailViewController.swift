//
//  GroupDetailViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/17.
//

import UIKit

class GroupDetailViewController: UIViewController {

        @IBOutlet weak var groupTitle: UINavigationItem!
        @IBOutlet weak var collectionView: UICollectionView!

        @IBOutlet weak var deleteMemberLabel: UILabel!
        @IBOutlet weak var deleteMemberBtn: UIButton!

        @IBOutlet weak var groupNameBtn: UIButton!
        @IBOutlet weak var selfNickBtn: UIButton!
    
        var groupItem: GroupItem?
        override func viewDidLoad() {
                super.viewDidLoad()
                collectionView.delegate = self
                collectionView.dataSource = self

                groupTitle.title = groupItem?.groupName

                self.collectionView.reloadData()
                if let group = groupItem, group.leader != Wallet.shared.Addr {
                        deleteMemberBtn.isHidden = true
                        deleteMemberLabel.isHidden = true
                }

                groupNameBtn.setTitle(groupItem?.groupName, for: .normal)
                selfNickBtn.setTitle(groupItem?.memberInfos[Wallet.shared.Addr!], for: .normal)
        }
        
        @IBAction func addMemberBtn(_ sender: UIButton) {
                let vc = instantiateViewController(vcID: "AddGrpMemberVC") as! GroupMemberViewController
                vc.isAddMember = true
                if let group = groupItem {
                        vc.groupItem = group
                        vc.existMember = group.memberIds
                }

                vc.notiMemberChange = { newGroupInfo in
                        self.groupItem = newGroupInfo
                        self.collectionView.reloadData()
                }
                self.navigationController?.pushViewController(vc, animated: true)
        }
    
        @IBAction func kickMemberBtn(_ sender: UIButton) {
                self.performSegue(withIdentifier: "KickMemberSeg", sender: self)
        }
    
        @IBAction func quitOrDismissGroup(_ sender: UIButton) {

                if let group = groupItem {
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
                        vc.groupItem = groupItem
                        vc.existMember = groupItem?.memberIds

                        vc.notiMemberChange = { newGroupInfo in
                                self.groupItem = newGroupInfo
                                self.collectionView.reloadData()
                        }
                }
        }
}

extension GroupDetailViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
                if let idCount = groupItem?.memberIds?.count {
                        print("\(idCount+1)")
                        return idCount+2
                }
                return 1
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
                if indexPath.row == 0 {
                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddCollectionCell", for: indexPath) as! AddCollectionCell
                        return cell
                }
                
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCollectionCell", for: indexPath) as! AvatarCollectionCell
                
                if let group = groupItem {
                        var ids: [String] = group.memberIds as! [String]
                        ids.append(group.leader!)
        
                        let id = ids[indexPath.row - 1]
                        cell.initApperance(id: id)
                }

                return cell
        }

}
