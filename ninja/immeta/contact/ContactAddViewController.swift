//
//  ContactAddViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/7/8.
//

import UIKit

class ContactAddViewController: UIViewController {
        
        @IBOutlet weak var searchAddr: UITextField!
        
        var contactID: String?
        
        override func viewDidLoad() {
                super.viewDidLoad()
                searchAddr.delegate = self
                self.hideKeyboardWhenTappedAround()
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
//                        self.toastMessage(title: "Empty ninja address")
                        return
                }
                guard ContactItem.IsValidContactID(addr) else {
                        self.toastMessage(title: "Invalid ninja address".locStr)
                        return
                }
                if Wallet.shared.Addr == addr {
                        self.toastMessage(title: "Invalid operation".locStr)
                        return
                }
                
                self.contactID = addr
                processByPeerID()
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "SearchNewSegue" {
                        let vc: SearchDetailViewController = segue.destination as! SearchDetailViewController
                        vc.uid = self.contactID!
                }
        }
        
        private func processByPeerID(){
                guard let _ = CombineConntact.cache[self.contactID!] else{
                        self.performSegue(withIdentifier: "SearchNewSegue", sender: self)
                        return
                }
                let vc = instantiateViewController(vcID: "ContactDetailsVC") as! ContactDetailsViewController
                vc.peerID = self.contactID!
                self.navigationController?.pushViewController(vc, animated: true)
        }
}

extension ContactAddViewController: ScannerViewControllerDelegate {
        func codeDetected(code: String) {
                print("------>>> scaned user code=[\(code)]")
                self.searchAddr.text = code
                guard ContactItem.IsValidContactID(code) else{
                        self.toastMessage(title: "Invaild ninja wallet address".locStr)
                        return
                }
                self.contactID = code
                processByPeerID()
        }
}

extension ContactAddViewController: UITextFieldDelegate {
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
                guard let addr = textField.text else {
                        return false
                }
                guard ContactItem.IsValidContactID(addr) else{
                        return false
                }
                self.contactID = addr
                processByPeerID()
                return true
        }
}
