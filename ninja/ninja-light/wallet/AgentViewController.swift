//
//  AgentViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/3.
//

import UIKit

class AgentViewController: UIViewController {

    @IBOutlet weak var doneStatus: UIButton!
    @IBOutlet weak var licenseDecode: UITextView!
    @IBOutlet weak var inputCode: UITextField!
    
    var license: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
    }
    
    @IBAction func backBarBtn(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func importBtn(_ sender: UIButton) {
        
        if let code = license {
            importLic(code)
        } else {
            if let input = inputCode.text {
                importLic(input)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ImportAgentSEG" {
            let vc : ScannerViewController = segue.destination as! ScannerViewController
            vc.delegate = self
        }
    }
    
    func importLic(_ license: String) {
        
        self.showIndicator(withTitle: "", and: "Importing")
        DispatchQueue.global().async {
            do {
                try AgentService.shared.importVaildLicense(license)
            } catch let err {
                DispatchQueue.main.async {
                    self.hideIndicator()
                    self.toastMessage(title: "import license err: \(err.localizedDescription)")
                }
                
            }
            DispatchQueue.main.async {
                self.hideIndicator()
                self.navigationController?.popViewController(animated: true)
            }
        }
        
    }

}

extension AgentViewController: ScannerViewControllerDelegate {
    
    func codeDetected(code: String) {
        self.license = code
        do {
            guard let decode = try AgentService.shared.decodeLicense(code) else {
                return
            }
            self.doneStatus.isHidden = false
            self.licenseDecode.text = decode
        } catch let err {
            self.toastMessage(title: "decode license err: \(err.localizedDescription)")
        }
    }

}
