//
//  TransferContactViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/27.
//

import UIKit

class TransferContactViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    var selectId:Int?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        tableView.rowHeight = 64
        tableView.tableFooterView = UIView()
        
//        reload()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        reload()
    }

    func reload() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TransferContactSEG" {
            let vc: ConfirmTransferViewController = segue.destination as! ConfirmTransferViewController
            if let id = selectId {
                vc.transAddress = ContactItem.CacheArray()[id].uid
            }
        }
        
    }
    
    
    @IBAction func returnItem(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension TransferContactViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ContactItem.cache.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTransferTableViewCell", for: indexPath)
        if let c = cell as? ContactTransferTableViewCell {
                let item = ContactItem.CacheArray()[indexPath.row]
                c.initWith(details:item, idx: indexPath.row)
                return c
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectId = indexPath.row
        self.performSegue(withIdentifier: "TransferContactSEG", sender: self)
    }
}