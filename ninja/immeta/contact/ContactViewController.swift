//
//  ViewController.swift
//  immeta
//
//  Created by wesley on 2021/3/30.
//

import UIKit

class ContactViewController: UIViewController{

        var selectedRow:Int?
        var NewCodeStr:String?
        var dataArry:[CombineConntact] = []
        @IBOutlet weak var tableview: UITableView!

        override func viewDidLoad() {
                super.viewDidLoad()
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(notifiAction(notification:)),
                                                       name: NotifyContactChanged,
                                                       object: nil)
                self.tableview.rowHeight = 60
                self.tableview.tableFooterView = UIView()
                dataArry =  CombineConntact.CacheArray()
        }

        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func notifiAction(notification:NSNotification){DispatchQueue.main.async {
                self.tableview.reloadData()
                self.dataArry =  CombineConntact.CacheArray()
        }
        }
}

extension ContactViewController:UITableViewDelegate, UITableViewDataSource{
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return CombineConntact.cache.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ContactItemTableViewCell", for: indexPath)
                if let c = cell as? ContactItemTableViewCell {
                        let item = self.dataArry[indexPath.row]
                        c.initWith(details: item)
                        return c
                }
                return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                self.selectedRow = indexPath.row
                self.NewCodeStr = nil//TODO:: test
                
                let vc = instantiateViewController(vcID: "ContactDetailsVC") as! ContactDetailsViewController
                
                if let itemid = self.NewCodeStr {
                        vc.peerID = itemid
                }
                
                if let idx = self.selectedRow {
                        vc.contactData = self.dataArry[idx]
                        vc.peerID = vc.contactData!.peerID
                }
                
                self.navigationController?.pushViewController(vc, animated: true)
        }
}

extension ContactViewController{
        
        @IBAction func openGroupListVC(_ gesture: UITapGestureRecognizer) {
                
                guard let vc = instantiateViewController(vcID: "GroupListViewControllerSID") as? GroupListViewController else{
                        return
                }
                self.navigationController?.pushViewController(vc, animated: true)
        }
}
