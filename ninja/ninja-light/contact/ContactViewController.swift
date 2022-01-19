//
//  ViewController.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit

class ContactViewController: UIViewController{

        var selectedRow:Int?
        var NewCodeStr:String?
        @IBOutlet weak var tableview: UITableView!

        override func viewDidLoad() {
                super.viewDidLoad()
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(notifiAction(notification:)),
                                                       name: NotifyContactChanged,
                                                       object: nil)
                self.tableview.rowHeight = 60
                self.tableview.tableFooterView = UIView()
                self.reload()
        }

        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                self.reload()
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func notifiAction(notification:NSNotification){
                self.reload()
        }
    
        private func reload(){
                ContactItem.LocalSavedContact()
                self.tableview.reloadData()
        }
}

extension ContactViewController:UITableViewDelegate, UITableViewDataSource{
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return ContactItem.cache.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ContactItemTableViewCell", for: indexPath)
                if let c = cell as? ContactItemTableViewCell {
                        let item = ContactItem.CacheArray()[indexPath.row]
                        let account = AccountItem.GetAccount(item.uid!)
                        c.initWith(details: item, idx: indexPath.row, account: account ?? AccountItem())
                        return c
                }
                return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                self.selectedRow = indexPath.row
                self.NewCodeStr = nil
                
                let vc = instantiateViewController(vcID: "ContactDetailsVC") as! ContactDetailsViewController
                
                if let itemid = self.NewCodeStr {
                        vc.itemUID = itemid

                }
                
                if let idx = self.selectedRow {
                        let item = ContactItem.CacheArray()[idx]
                        vc.itemData = item
                }
                
                self.navigationController?.pushViewController(vc, animated: true)

        }
}
