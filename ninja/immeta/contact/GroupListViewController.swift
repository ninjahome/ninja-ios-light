//
//  GroupListViewController.swift
//  immeta
//
//  Created by 郭晓芙 on 2021/12/28.
//

import UIKit

class GroupListViewController: UIViewController {
        
        @IBOutlet weak var tableView: UITableView!
        
        var groupArray:[GroupItem] = []
        var indexPathCache:[String:IndexPath] = [:]
        
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
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(updateGroupList(notification:)),
                                                       name: NotifyGroupCreated,
                                                       object: nil)
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(updateGroupAvatarOrName(notification:)),
                                                       name: NotifyGroupNameOrAvatarChanged,
                                                       object: nil)
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(groupItemDeleted(notification:)),
                                                       name: NotifyGroupDeleteChanged,
                                                       object: nil)
                
        }
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func groupItemDeleted(notification: NSNotification) {
                guard let gid = notification.object as? String else{
                        simpleReload()
                        return
                }
                
                DispatchQueue.main.async {
                        print("------>new group item\(gid) deleted")
                        guard let idx = self.indexPathCache[gid] else{
                                self.simpleReload()
                                return
                        }
                        guard idx.row < self.groupArray.count else{
                                self.simpleReload()
                                return
                        }
                        
                        self.groupArray.remove(at: idx.row)
                        self.tableView.beginUpdates()
                        self.tableView.deleteRows(at: [idx], with: .automatic)
                        self.tableView.endUpdates()
                }
        }
        @objc func updateGroupAvatarOrName(notification: NSNotification) {
                //                simpleReload()
                guard let gid = notification.object as? String,
                      let newItem =   GroupItem.cache[gid]else{
                              simpleReload()
                              return
                      }
                
                DispatchQueue.main.async {
                        print("------>new group item\(gid) update")
                        guard let idx = self.indexPathCache[gid] else{
                                self.simpleReload()
                                return
                        }
                        self.groupArray[idx.row] = newItem
                        self.tableView.beginUpdates()
                        self.tableView.reloadRows(at: [idx], with: .automatic)
                        self.tableView.endUpdates()
                }
        }
        
        @objc func updateGroupList(notification: NSNotification) {
                if  let gid = notification.object as? String{
                        print("------>new item\(gid) create")
                        //TODO::
                }
                simpleReload()
        }
        private func simpleReload(){DispatchQueue.main.async {
                self.groupArray =  GroupItem.CacheArray()
                self.indexPathCache.removeAll()
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
                indexPathCache[item.gid] = indexPath
                c.initWith(detail: item, idx: indexPath.row)
                return c
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                let item = groupArray[indexPath.row]
                vc.IS_GROUP = true
                vc.peerUid = item.gid
                self.navigationController?.pushViewController(vc, animated: true)
        }
}
