//
//  CreateGroupViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/7/30.
//

import UIKit

class CreateGroupViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var finishBtn: UIButton!

    var selectedIndexs = [Int]()
    var setEnable: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 64
        self.tableView.tableFooterView = UIView()
        
        self.reload()
    }
    
    @IBAction func returnBackItem(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func reload(){
        ContactItem.LocalSavedContact()
        
        DispatchQueue.main.async {
                self.tableView.reloadData()
        }
    }
    
    func enableOrDisableCompleteBtn(number: Int) {
        finishBtn.setTitle("完成(\(number))", for: .normal)
        
        if setEnable {
            finishBtn.backgroundColor = UIColor(hex: "3B877F")
        } else {
            finishBtn.backgroundColor = UIColor(hex: "A9A9AE")
        }
    }


}

extension CreateGroupViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ContactItem.cache.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CreateGroupMemberTableViewCell", for: indexPath)
        
        if let c = cell as? CreateGroupMemberTableViewCell {
            let item = ContactItem.CacheArray()[indexPath.row]
            c.initWith(details: item, idx: indexPath.row)
            c.cellDelegate = self
            
            return c
        }
        
        return cell
    }
    
}

extension CreateGroupViewController: CellClickDelegate {
    
    func addDidClick(_ idx: Int) {
        
        if !selectedIndexs.contains(idx) {
            selectedIndexs.append(idx)
        }
        
        if selectedIndexs.count > 1 {
            self.setEnable = true
        }
        
        enableOrDisableCompleteBtn(number: selectedIndexs.count)
        
        print("selected list \(selectedIndexs)")
    }
    
    func delDidClick(_ idx: Int) {
        
        if let existedIdx = selectedIndexs.firstIndex(of: idx) {
            selectedIndexs.remove(at: existedIdx)
        }
        
        if selectedIndexs.count < 2 {
            self.setEnable = false
        }
        
        enableOrDisableCompleteBtn(number: selectedIndexs.count)
        
        print("selected list \(selectedIndexs)")
    
    }

}
