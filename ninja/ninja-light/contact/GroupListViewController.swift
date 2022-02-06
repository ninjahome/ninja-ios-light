//
//  GroupListViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/28.
//

import UIKit

class GroupListViewController: UIViewController {
        
        @IBOutlet weak var tableView: UITableView!
        
        var groupArray:[GroupItem] = []
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.tableView.delegate = self
                self.tableView.dataSource = self
                self.tableView.rowHeight = 60
                self.tableView.tableFooterView = UIView()
                groupArray = GroupItem.CacheArray()
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(updateGroupList(notification:)),
                                                       name: NotifyGroupChanged,
                                                       object: nil)
                
        }
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func updateGroupList(notification: NSNotification) {
                if  let gid = notification.object as? String{
                        print("------>new item\(gid) create")
                }
                groupArray =  GroupItem.CacheArray()
                self.reload()
        }
        
        private func reload() {DispatchQueue.main.async {
                self.tableView.reloadData()
        }
        }
}

extension GroupListViewController: UITableViewDelegate, UITableViewDataSource {
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return groupArray.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                
                let cell = tableView.dequeueReusableCell(withIdentifier: "GroupItemTableViewCell", for: indexPath)
                guard let c = cell as? GroupItemTableViewCell else{
                        return cell
                }
                let item = groupArray[indexPath.row]
                c.initWith(detail: item, idx: indexPath.row)
                return c
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                let item = groupArray[indexPath.row]
                vc.groupData = item
                vc.IS_GROUP = true
                vc.peerUid = item.gid
                self.navigationController?.pushViewController(vc, animated: true)
        }
}
