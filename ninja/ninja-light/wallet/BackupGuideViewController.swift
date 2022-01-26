//
//  BackupGuideViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/1/6.
//

import UIKit

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
                if qr != nil {
                        UIImageWriteToSavedPhotosAlbum(qr!, nil, nil, nil)
                        self.toastMessage(title: "Save success")
                        afterWallet()
                }
        }
        
        @IBAction func skipBackup(_ sender: UIButton) {
//                self.performSegue(withIdentifier: "EndBackupSEG", sender: self)
                afterWallet()
        }
        
        
}
