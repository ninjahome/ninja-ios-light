//
//  ContactAddViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/7/8.
//

import UIKit

class ContactAddViewController: UIViewController {
    
    
    @IBOutlet weak var searchAddr: UITextField!
    
    var contactItem: ContactItem?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        searchAddr.delegate = self
        self.hideKeyboardWhenTappedAround()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)

    }
     
    @IBAction func CancelAdd(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

//    @IBAction func ScanQR(_ sender: UIButton) {
//        self.performSegue(withIdentifier: "ShowQRScanerID", sender: self)
//    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SearchNewSegue" {
            let vc: SearchDetailViewController = segue.destination as! SearchDetailViewController
            vc.uid = self.searchAddr.text
        }
        
        if segue.identifier == "SearchExistSegue" {
            let vc: ContactDetailsViewController = segue.destination as! ContactDetailsViewController
            vc.itemData = self.contactItem
            
        }
        
        if segue.identifier == "ShowAddrQRID"{
             let vc : ScannerViewController = segue.destination as! ScannerViewController
             vc.delegate = self
        }
    }
    
}


extension ContactAddViewController: ScannerViewControllerDelegate {
        
        func codeDetected(code: String) {
                NSLog("\(code)")
                if ContactItem.IsValidContactID(code) {
                    if let item = ContactItem.GetContact(code) {
                        self.contactItem = item
                        self.performSegue(withIdentifier: "SearchExistSegue", sender: self)
                    } else {
                        self.performSegue(withIdentifier: "SearchNewSegue", sender: self)
                    }
                } else {
                    self.toastMessage(title: "invalid ninja address")
                    return
                }

        }
}


extension ContactAddViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let addr = textField.text else {
            return false
        }
        if ContactItem.IsValidContactID(addr) {
            if let item = ContactItem.GetContact(addr) {
                self.contactItem = item
                self.performSegue(withIdentifier: "SearchExistSegue", sender: self)
            } else {
                self.performSegue(withIdentifier: "SearchNewSegue", sender: self)
            }
            
            return true
        }

        return false
        
    }
//    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
//        if text == "\n" {
//            guard let addr = self.searchAddr.text, addr != "" else {
//                return false
//            }
//
//            if let item = ContactItem.GetContact(addr) {
//                self.contactItem = item
//                self.performSegue(withIdentifier: "SearchExistSegue", sender: self)
//            } else {
//                self.performSegue(withIdentifier: "SearchNewSegue", sender: self)
//            }
//        }
//        return true
//    }
}
