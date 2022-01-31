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
        var refreshControl = UIRefreshControl()
        var sortedArray: [ChatItem] = []
        var initErr: Error?

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
        
        //TODO:: optimization
        func updateMsgBadge() {
                let total = ChatItem.getTotalUnreadNo()
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
                ServiceDelegate.workQueue.async { [weak self] in
                        self?.sortedArray = ChatItem.SortedArra()
                        DispatchQueue.main.async {
                                self?.tableView.reloadData()
                                self?.updateMsgBadge()
                        }
                }
        }
        
        @objc func wsOnlineErr(notification: NSNotification) {
                print("WSOnline error....")
        }
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                self.hideConnectingTips()
                updateMsgBadge()
                guard Wallet.shared.IsActive() else {
                        self.performSegue(withIdentifier: "ShowAutherSEG", sender: self)
                        return
                }
        }
    
        private func hideConnectingTips() {
                DispatchQueue.main.async {
                        self.tableTopConstraint.constant = 0
                        self.errorTips.isHidden = true
                        self.errorTips.text = ""
                        self.title = "消息"
                }
        }

        private func showConnectingTips() {
                DispatchQueue.main.async {
                        self.title = "连接中..."
                }
        }
        
        private func showConnErrorTips() {
                DispatchQueue.main.async {
                        self.tableTopConstraint.constant = 30
                        self.errorTips.isHidden = false
                        self.errorTips.text = "网络断开"
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
                        item.resetUnread()
                        vc.peerUid = item.ItemID
                        vc.IS_GROUP = item.isGroup
                        return
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
                        let item = sortedArray[indexPath.row]
                        c.initWith(details: item, idx: indexPath.row)
                        return c
                }
                return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                self.SelectedRowID = indexPath.row
                self.performSegue(withIdentifier: "ShowMessageDetailsSEG", sender: self)
        }

        func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
                if editingStyle == .delete {
                        let item = sortedArray[indexPath.row]
                        sortedArray.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        ChatItem.remove(item.ItemID)
                }
        }
}
