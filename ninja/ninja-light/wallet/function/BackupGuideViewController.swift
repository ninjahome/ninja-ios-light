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
        @IBOutlet weak var infoView: UIView!
        
        var qr: UIImage?
        var ifAccountInit = true
        override func viewDidLoad() {
                super.viewDidLoad()
                self.view.layer.contents = UIImage(named: "bg-img")?.cgImage
                qrImage.image = getQRCode()
                address.text = Wallet.shared.Addr!
        }
        
        func getQRCode() -> UIImage? {
                guard let wJson = Wallet.shared.wJson else { return nil }
                let qrImg = generateQRCode(from: wJson, foreColor: UIColor.walletKey)
                self.qr = qrImg
                return qrImg
        }
        
        @IBAction func backupQR(_ sender: UIButton) {
                
                guard let data = qr else {
                        self.toastMessage(title: "Invalid Account, please reboot".locStr)
                        return
                }
                
                if let exportImg = generateViewImg(info: infoView) {
                        UIImageWriteToSavedPhotosAlbum(exportImg, self, nil, nil)
                } else {
                        UIImageWriteToSavedPhotosAlbum(data, nil, nil, nil)
                }
                self.finish()
        }
        
        @IBAction func skipBackup(_ sender: UIButton) {
                finish()
        }
        
        private func finish(){
                
                DispatchQueue.main.async {
                        if self.ifAccountInit{
                                afterWallet()
                                return
                        }
                        self.dismiss(animated: true)
                }
        }
}
