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
        NotificationCenter.default.addObserver(self, selector:#selector(notifiAction(notification:)),
                                                       name: NotifyContactChanged, object: nil)
        
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//                if segue.identifier == "ShowQRScanerID"{
//                        let vc : ScannerViewController = segue.destination as! ScannerViewController
//                        vc.delegate = self
//                }else
        if segue.identifier == "ShowContactDetailSeg"{
            let vc : ContactDetailsViewController = segue.destination as! ContactDetailsViewController
            guard let itemid = self.NewCodeStr else {
                if let idx = self.selectedRow {
                    let item = ContactItem.CacheArray()[idx]
                    vc.itemData = item
                }
                return
            }
            
            vc.itemUID = itemid
//                        guard let idx = self.selectedRow else{
//                                vc.itemUID = self.NewCodeStr
//                                return
//                        }
//                        let item = ContactItem.CacheArray()[idx]
//                        vc.itemData = item
        }
    }
    
    
//        @IBAction func NewContact(_ sender: UIBarButtonItem) {
//
//                let alertController = UIAlertController(title: nil, message: "Alert message.", preferredStyle: .actionSheet)
//                alertController.modalPresentationStyle = .popover
//
//                let defaultAction = UIAlertAction(title: "Scan QR", style: .default, handler: { (alert: UIAlertAction!) -> Void in
//                        self.performSegue(withIdentifier: "ShowQRScanerID", sender: self)
//                })
//
//                let deleteAction = UIAlertAction(title: "New", style: .default, handler: { (alert: UIAlertAction!) -> Void in
//                        self.selectedRow = nil
//                        self.NewCodeStr = nil
//                        self.performSegue(withIdentifier: "ShowContactDetailSeg", sender: self)
//                })
//
//                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
//
//                alertController.addAction(defaultAction)
//                alertController.addAction(deleteAction)
//                alertController.addAction(cancelAction)
//
//                if let popoverController = alertController.popoverPresentationController {
//                        popoverController.barButtonItem = sender
//                }
//
//                self.present(alertController, animated: true, completion: nil)
//        }
    
    private func reload(){
        ContactItem.LocalSavedContact()
//        DispatchQueue.main.async {
            self.tableview.reloadData()
//        }
    }
}
//
//extension ContactViewController:ScannerViewControllerDelegate{
//
//        func codeDetected(code: String) {
//                NSLog("\(code)")
//                if ContactItem.IsValidContactID(code) {
////                        self.toastMessage(title: "invalid ninja address")
//                    self.NewCodeStr = code
//
//                    self.performSegue(withIdentifier: "ShowContactDetailSeg", sender: self)
////                        return
//                } else {
//                    self.toastMessage(title: "invalid ninja address")
//                    return
//                }
//
//
//        }
//}

extension ContactViewController:UITableViewDelegate, UITableViewDataSource{
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
                return ContactItem.cache.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ContactItemTableViewCell", for: indexPath)
                if let c = cell as? ContactItemTableViewCell{
                        let item = ContactItem.CacheArray()[indexPath.row]
//                    print("contact item \(String(describing: item.sortPinyin))")
                        c.initWith(details:item, idx: indexPath.row)
                        return c
                }
                return cell
        }
        
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
                self.selectedRow = indexPath.row
                self.NewCodeStr = nil
                self.performSegue(withIdentifier: "ShowContactDetailSeg", sender: self)
        }
}
