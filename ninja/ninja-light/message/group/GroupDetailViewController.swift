//
//  GroupDetailViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/17.
//

import UIKit

struct Avatar {
    var color: String
    var text: String
    
    init(_ c: String, _ t: String) {
        self.color = c
        self.text = t
    }
}

class GroupDetailViewController: UIViewController {
    
    var groupItem: GroupItem?
//    var avatars: Dictionary<String, Avatar> = [:]
    
    @IBOutlet weak var groupTitle: UINavigationItem!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var deleteMemberLabel: UILabel!
    @IBOutlet weak var deleteMemberBtn: UIButton!
    
    @IBOutlet weak var groupNameBtn: UIButton!
    @IBOutlet weak var selfNickBtn: UIButton!
    
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
        self.performSegue(withIdentifier: "AddGroupMemberSeg", sender: self)
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
        if segue.identifier == "AddGroupMemberSeg" {
            let vc: GroupMemberViewController = segue.destination as! GroupMemberViewController
            vc.isAddMember = true
            if let group = groupItem {
                vc.groupItem = group
                vc.existMember = group.memberIds
            }
            
            vc.notiMemberChange = { newGroupInfo in
                self.groupItem = newGroupInfo
                self.collectionView.reloadData()
            }
        }
        
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
    
//    func getAvatars() {
//        guard let group = groupItem else {
//            return
//        }
//
//        for (id, nick) in group.memberInfos {
//            let color = ContactItem.GetAvatarColor(by: id)
//            let avaText = GroupItem.GetAvatarText(by: nick != "" ? nick : id)
//
//            self.avatars[id] = Avatar.init(color, avaText)
//        }
//
//    }

}

extension GroupDetailViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let idCount = groupItem?.memberInfos.count {
            print("\(idCount)")
            return idCount+1
        }
        
        return 1

    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddCollectionCell", for: indexPath) as! AddCollectionCell
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCollectionCell", for: indexPath) as! AvatarCollectionCell
        if let ids = groupItem?.memberIds {
            let id = ids[indexPath.row - 1] as! String
            cell.initApperance(id: id)
//            cell.ava = avatars[id]
//            cell.uid = id
        }
        return cell
        
    }
    
}
