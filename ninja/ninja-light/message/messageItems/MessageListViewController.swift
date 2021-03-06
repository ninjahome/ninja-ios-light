//
//  MessageListViewController.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import UIKit

class MessageListViewController: UIViewController{
        
        @IBOutlet weak var navTitle: UINavigationItem!
        @IBOutlet weak var errorTips: UILabel!
        @IBOutlet weak var tableTopConstraint: NSLayoutConstraint!
        @IBOutlet weak var tableView: UITableView!
        
        @IBOutlet weak var moreAction: UIBarButtonItem!
        @IBOutlet weak var moreActionContent: UIView!
        
        @IBOutlet weak var addActions: UIButton!
        
        var SelectedRowID: Int? = nil
        var sortedArray: [ChatItem] = []
        var indexCache:[String:IndexPath] = [:]
        
        override func viewDidLoad() {
                super.viewDidLoad()
                tableView.rowHeight = 80
                tableView.tableFooterView = UIView()
                showConnectingTips()
                
                sortedArray = ChatItem.SortedArra()
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(updateLatestItem(notification:)),
                                                       name: NotifyMsgSumChanged,
                                                       object: nil)
                
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(updateLatestItem(notification:)),
                                                       name: NotifyGroupChanged,
                                                       object: nil)
                
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(updateLatestItem(notification:)),
                                                       name: NotifyGroupCreated,
                                                       object: nil)
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(updateGroupAvatarOrName(notification:)),
                                                       name: NotifyGroupNameOrAvatarChanged,
                                                       object: nil)
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(groupDeleteFromChatList(notification:)),
                                                       name: NotifyGroupDeleteChanged,
                                                       object: nil)
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(wsOffline(notification:)),
                                                       name: NotifyWebsocketOffline,
                                                       object: nil)
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(wsDidOnline(notification:)),
                                                       name: NotifyWebsocketOnline,
                                                       object: nil)
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(wsOnlineErr(notification:)),
                                                       name: NotifyOnlineError,
                                                       object: nil)
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(updateLatestItem(notification:)),
                                                       name: NotifyContactChanged,
                                                       object: nil)
                
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
                
                toggleAddItem(currentStatus: false)
        }
        
        @IBAction func moreAction(_ sender: UIBarButtonItem) {
                toggleAddItem(currentStatus: moreActionContent.isHidden)
        }
        
        func toggleAddItem(currentStatus isHidden: Bool) {
                
                if isHidden {
                        moreActionContent.isHidden = false
                        moreAction.image = UIImage(named: "x_icon")
                } else {
                        moreActionContent.isHidden = true
                        moreAction.image = UIImage(named: "+_icon")
                }
                
        }
        
        func updateMsgBadge() {
                let total = ChatItem.TotalUnreadNo
                var totalStr: String?
                if total != 0 {
                        totalStr = String(total)
                }
                self.navigationController?.tabBarItem.badgeValue = totalStr
        }
        
        //MARK: - object c
        @objc func wsOffline(notification: NSNotification) {
                print("Client shutdown....")
                self.showConnectingTips()
        }
        @objc func wsDidOnline(notification: NSNotification) {
                print("Client online....")
                self.hideConnectingTips()
        }
        
        @objc func updateLatestItem(notification: NSNotification) {
                self.simpleReload()
        }
        private func simpleReload(){
                DispatchQueue.main.async {
                        self.indexCache.removeAll()
                        self.sortedArray = ChatItem.SortedArra()
                        self.tableView.reloadData()
                        self.updateMsgBadge()
                }
        }
        @objc func wsOnlineErr(notification: NSNotification) {
                print("WSOnline error....")
        }
        
        @objc func groupDeleteFromChatList(notification: NSNotification) {
                guard let gid = notification.object as? String else{
                        self.simpleReload()
                        return
                }
                
                DispatchQueue.main.async {
                        print("------>new group item\(gid) delete")
                        guard let idx = self.indexCache[gid] else{
                                self.simpleReload()
                                return
                        }
                        guard idx.row < self.sortedArray.count else{
                                self.simpleReload()
                                return
                        }
                        self.removeOneCellAtRow(idx: idx)
                }
        }
        private func removeOneCellAtRow(idx:IndexPath){
                let item = self.sortedArray[idx.row]
                item.resetUnread()
                self.sortedArray.remove(at: idx.row)
                
                try? ChatItem.remove(item.ItemID)
                MessageItem.removeRead(item.ItemID)
                self.updateMsgBadge()
                
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [idx], with: .automatic)
                self.tableView.endUpdates()
        }
        @objc func updateGroupAvatarOrName(notification: NSNotification) {
                guard let gid = notification.object as? String, let newItem = ChatItem.getItem(cid: gid) else{
                        self.simpleReload()
                        return
                }
                
                DispatchQueue.main.async {
                        print("------>new group item\(gid) update")
                        guard let idx = self.indexCache[gid] else{
                                self.simpleReload()
                                return
                        }
                        self.sortedArray[idx.row] = newItem
                        self.tableView.beginUpdates()
                        self.tableView.reloadRows(at: [idx], with: .automatic)
                        self.tableView.endUpdates()
                }
        }
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                guard Wallet.shared.IsActive() else {
                        self.performSegue(withIdentifier: "ShowAutherSEG", sender: self)
                        return
                }
                self.hideConnectingTips()
                updateMsgBadge()
        }
        
        private func hideConnectingTips() {
                DispatchQueue.main.async {
                        self.tableTopConstraint.constant = 0
                        self.errorTips.isHidden = true
                        self.errorTips.text = ""
                        self.title = "??????"
                }
        }
        
        private func showConnectingTips() {
                DispatchQueue.main.async {
                        self.title = "?????????..."
                }
        }
        
        private func showConnErrorTips() {
                DispatchQueue.main.async {
                        self.tableTopConstraint.constant = 30
                        self.errorTips.isHidden = false
                        self.errorTips.text = "????????????"
                }
        }
        
        // MARK: - Navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                
                if segue.identifier == "ShowMessageDetailsSEG"{
                        guard let idx = self.SelectedRowID else {
                                return
                        }
                        guard let vc = segue.destination as? MsgViewController else {
                                return
                        }
                        
                        let item = sortedArray[idx]
                        vc.peerUid = item.ItemID
                        vc.IS_GROUP = item.isGroup
                        CDManager.shared.saveContext()
                        return
                }
                if segue.identifier == "ShowAutherSEG"{
                        guard let vc = segue.destination as? AuthorViewController else {
                                return
                        }
                        vc.delegate = self
                }
        }
}

// MARK: - tableview
extension MessageListViewController: UITableViewDelegate, UITableViewDataSource {
        
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return sortedArray.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MesasgeItemTableViewCell", for: indexPath)
                if let c = cell as? MesasgeItemTableViewCell {
                        let indx = indexPath.row
                        let item = sortedArray[indx]
                        indexCache[item.ItemID] = indexPath
                        c.initWith(details: item)
                        return c
                }
                return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                self.SelectedRowID = indexPath.row
                
                let item = self.sortedArray[indexPath.row]
                item.resetUnread()
                self.performSegue(withIdentifier: "ShowMessageDetailsSEG", sender: self)
                tableView.beginUpdates()
                tableView.reloadRows(at: [indexPath], with: .automatic)
                tableView.endUpdates()
        }
        
        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
                guard editingStyle == .delete else{
                        return
                }
                
                self.removeOneCellAtRow(idx: indexPath)
                CDManager.shared.saveContext()
        }
}
extension MessageListViewController:WalletDelegate{
        
        func OpenSuccess() {
                ServiceDelegate.workQueue.async {
                        ServiceDelegate.InitService()
                        self.sortedArray = ChatItem.SortedArra()
                        DispatchQueue.main.async {
                                self.updateMsgBadge()
                                self.tableView.reloadData()
                        }
                }
        }
}
