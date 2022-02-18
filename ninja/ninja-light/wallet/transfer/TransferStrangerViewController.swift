//
//  TransferStrangerViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/27.
//

import UIKit

class TransferStrangerViewController: UIViewController {

        @IBOutlet weak var inputTransferAddr: UITextView!

        var transferId: String?

        override func viewDidLoad() {
                super.viewDidLoad()

                self.hideKeyboardWhenTappedAround()
        }
    
        @IBAction func returnItem(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "TransferStrangerSEG" {
                        let vc: ConfirmTransferViewController = segue.destination as! ConfirmTransferViewController
                        vc.transAddress = transferId
                }
        }
        
        @IBAction func scanner(_ sender: UIButton) {
                let vc = instantiateViewController(vcID: "ScannerVC") as! ScannerViewController
                vc.delegate = self
                self.present(vc, animated: true, completion: nil)
        }
        
        @IBAction func confirmTransferAddr(_ sender: UIButton) {
                guard let addr = inputTransferAddr.text else {
                        return
                }
                transferId = addr
                self.performSegue(withIdentifier: "TransferStrangerSEG", sender: self)
        }
    
}

extension TransferStrangerViewController: ScannerViewControllerDelegate {
        func codeDetected(code: String) {
                inputTransferAddr.text = code
        }
}
