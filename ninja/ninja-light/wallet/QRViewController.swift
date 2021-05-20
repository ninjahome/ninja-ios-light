//
//  QRViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/5/17.
//

import UIKit

class QRViewController: UIViewController {

    @IBOutlet weak var qrImg: UIImageView!
    var qr:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.contents = UIImage(named: "bg-img")?.cgImage
        
        qrImg.image = getQRCode()
    }
    
    func getQRCode() -> UIImage? {
        guard let addr = Wallet.shared.Addr else { return nil }
        let qrImg = generateQRCode(from: addr)
        self.qr = qrImg
        return qrImg
    }
    
    @IBAction func copyAddr(_ sender: UIButton) {
        UIPasteboard.general.string = Wallet.shared.Addr
        self.toastMessage(title: "Copy Success")
    }
    
    
    @IBAction func downloadQR(_ sender: UIButton) {
        if qr != nil {
            UIImageWriteToSavedPhotosAlbum(qr!, nil, nil, nil)
            self.toastMessage(title: "Save success")
        }
    }
    
    @IBAction func shareQR(_ sender: UIButton) {
        self.toastMessage(title: "Waiting...")
    }
    
    
}
