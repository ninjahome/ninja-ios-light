//
//  ManageViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/5/22.
//

import UIKit

class ManageViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let item = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        self.navigationItem.backBarButtonItem = item
    }
    
    @IBAction func exportAccount(_ sender: UIButton) {
        
        if let walletJson = Wallet.shared.wJson,
           let walletImg = generateQRCode(from: walletJson) {
            NSLog("walletJson \(walletJson)")
            UIImageWriteToSavedPhotosAlbum(walletImg, nil, nil, nil)
            self.toastMessage(title: "Save success")
        } else {
            self.toastMessage(title: "Save Failed")
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowImportScannerID" {
            let vc : ScannerViewController = segue.destination as! ScannerViewController
            vc.delegate = self
        }
    }
    
}

extension ManageViewController: ScannerViewControllerDelegate {
    func codeDetected(code: String) {
        NSLog("\(code)")
        guard let addr = Wallet.shared.serializeWalletJson(cipher: code) else {
            self.toastMessage(title: "invaild ninja wallet address")
            return
        }
        if Wallet.shared.Addr != nil {
            self.showPwdInput(title: "请输入密码导入账号", placeHolder: "请输入密码") {[weak self] (auth, isOK) in
                if let pwd = auth, isOK {
                    do {
                        cleanAllData()
                        
                        WebsocketSrv.shared.Offline()
                        
                       
                        ServiceDelegate.InitConfig()
                        
                        try Wallet.shared.Import(cipher: code, addr: addr, auth: pwd)
                        self?.navigationController?.popToRootViewController(animated: true)
//                        let online_err = WebsocketSrv.shared.Online()
                        print("new wallet \(String(describing: Wallet.shared.Addr))")
                        
                    } catch let err as NSError {
                        self?.toastMessage(title: err.localizedDescription)
                    }
                }
            }
        }
    }
}
