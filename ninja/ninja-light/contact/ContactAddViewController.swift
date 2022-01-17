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

//                self.navigationController?.setNavigationBarHidden(true, animated: true)
        }

        override func viewDidLoad() {
                super.viewDidLoad()
                searchAddr.delegate = self
                self.hideKeyboardWhenTappedAround()
        }
    
        override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
//                self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
        
        @IBAction func backBarBtn(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }
        
        @IBAction func scanner(_ sender: UIButton) {
                let vc = instantiateViewController(vcID: "ScannerVC") as! ScannerViewController
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
        }
        
        @IBAction func search(_ sender: UIButton) {
                guard let addr = searchAddr.text else {
                        return
                }
                if ContactItem.IsValidContactID(addr) {
                        if let item = ContactItem.GetContact(addr) {
                                self.contactItem = item
                                pushToExistContact()
                        } else {
                                self.performSegue(withIdentifier: "SearchNewSegue", sender: self)
                        }
                }
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "SearchNewSegue" {
                        let vc: SearchDetailViewController = segue.destination as! SearchDetailViewController
                        vc.uid = self.searchAddr.text
                }
        }
        
        func pushToExistContact() {
                let vc = instantiateViewController(vcID: "ContactDetailsVC") as! ContactDetailsViewController
                vc.itemData = self.contactItem
                
                self.navigationController?.pushViewController(vc, animated: true)
        }
}

extension ContactAddViewController: ScannerViewControllerDelegate {
        func codeDetected(code: String) {
                NSLog("\(code)")
                if ContactItem.IsValidContactID(code) {
                        if let item = ContactItem.GetContact(code) {
                                self.contactItem = item
                                pushToExistContact()
                        } else {
                                self.searchAddr.text = code
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
                                pushToExistContact()
                        } else {
                                self.performSegue(withIdentifier: "SearchNewSegue", sender: self)
                        }

                        return true
                }

                return false

        }

}
