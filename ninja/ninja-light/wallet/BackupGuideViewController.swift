//
//  BackupGuideViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/1/6.
//

import UIKit
import Photos

class BackupGuideViewController: UIViewController {
        
        @IBOutlet weak var address: UILabel!
        @IBOutlet weak var qrImage: UIImageView!
        
        var qr: UIImage?
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.view.layer.contents = UIImage(named: "bg-img")?.cgImage
                qrImage.image = getQRCode()
                address.text = Wallet.shared.Addr!
        }
        
        func getQRCode() -> UIImage? {
                guard let wJson = Wallet.shared.wJson else { return nil }
                let qrImg = generateQRCode(from: wJson)
                self.qr = qrImg
                return qrImg
        }
        
        @IBAction func backupQR(_ sender: UIButton) {
                guard let data = qr else {
                        self.toastMessage(title: "Invalid Account, please reboot".locStr)
                        return
                }
                UIImageWriteToSavedPhotosAlbum(data, nil, nil, nil)
                self.toastMessage(title: "Save success".locStr)
                afterWallet()
        }
        
        @IBAction func copyAddr(_ sender: UIButton) {
                UIPasteboard.general.string = Wallet.shared.Addr!
                self.toastMessage(title: "Copy Success".locStr, duration: 1)
        }
        
        @IBAction func skipBackupAcc(_ sender: UIBarButtonItem) {
                afterWallet()
        }
        
        
        @IBAction func backToPrevious(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }
        
}
