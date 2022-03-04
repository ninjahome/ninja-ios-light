//
//  MsgKeepDaysTableViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/3/4.
//

import UIKit

class MsgKeepDaysTableViewController: UITableViewController {
        let keepDaysList: [Int16] = [15, 7, 1, 0]
        var selectedIndex: IndexPath?
        
        override func viewDidLoad() {
                super.viewDidLoad()
        }

    // MARK: - Table view data source

        override func numberOfSections(in tableView: UITableView) -> Int {
                // #warning Incomplete implementation, return the number of sections
                return 1
        }

        override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                // #warning Incomplete implementation, return the number of rows
                return keepDaysList.count
        }
        
        override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                guard let cell = tableView.cellForRow(at: indexPath) else {
                        return
                }
                
                if let selected = selectedIndex,
                   let preCell = tableView.cellForRow(at: selected) {
                        preCell.accessoryType = .none
                }
                
                selectedIndex = indexPath
                cell.accessoryType = .checkmark
                print("checkout \(indexPath.row)")
                let day = keepDaysList[indexPath.row]
                if let err = ConfigItem.updateKeepDays(day) {
                        print("update keep days faild: \(err.localizedDescription ?? "")")
                }
        }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "keepDaysID", for: indexPath) as! KeepDaysTableViewCell
                let day = keepDaysList[indexPath.row]
                cell.initCell(days: Int(day))
                let keepDays = ConfigItem.shared.keepDays
                if keepDays == day {
                        selectedIndex = indexPath
                        cell.accessoryType = .checkmark
                }
                return cell
        }
        

        @IBAction func backBar(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }

}
