//
//  GroupListViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/28.
//

import UIKit

class GroupListViewController: UIViewController {

//        var selectedRow: Int?
        @IBOutlet weak var tableView: UITableView!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.tableView.delegate = self
                self.tableView.dataSource = self
                self.tableView.rowHeight = 60
                self.tableView.tableFooterView = UIView()
                self.reload()
        }
        
        private func reload() {
                GroupItem.LocalSavedGroup()
                self.tableView.reloadData()
        }


}

extension GroupListViewController: UITableViewDelegate, UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return GroupItem.cache.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "GroupItemTableViewCell", for: indexPath)
                if let c = cell as? GroupItemTableViewCell {
                        let item = GroupItem.CacheArray()[indexPath.row]
                        c.initWith(detail: item, idx: indexPath.row)
                        return c
                }
                return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//                self.selectedRow = indexPath.row
                let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                let item = GroupItem.CacheArray()[indexPath.row]
                vc.groupData = item
                vc.IS_GROUP = true
                vc.peerUid = item.gid!
                self.navigationController?.pushViewController(vc, animated: true)
//                self.performSegue(withIdentifier: "GrpMsgDetailSEG", sender: self)
        }
}
