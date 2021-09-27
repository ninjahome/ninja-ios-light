//
//  QRViewController.swift
//  ninja-light
//
//  Created by akatuki on 2021/5/17.
//

import UIKit

class QRViewController: UIViewController {

    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var qrImg: UIImageView!
    @IBOutlet weak var ninjaAddr: UILabel!
    var qr:UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer.contents = UIImage(named: "bg-img")?.cgImage
        
        let addr = Wallet.shared.Addr!
        ninjaAddr.text = "Ninja Address: \(addr)"
        
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
        
        if let exportImg = generateViewImg(info: infoView) {
            UIImageWriteToSavedPhotosAlbum(exportImg, self, nil, nil)
            self.toastMessage(title: "Save success")
        } else if qr != nil {
            UIImageWriteToSavedPhotosAlbum(qr!, nil, nil, nil)
            self.toastMessage(title: "Save success")
        }
        
    }
        
    @IBAction func shareQR(_ sender: UIButton) {
        guard let exportImg = generateViewImg(info: infoView) else {
            return
        }
        let activityViewCtrl = UIActivityViewController(activityItems: [exportImg], applicationActivities: nil)
        activityViewCtrl.excludedActivityTypes = [.copyToPasteboard, .postToVimeo, .postToFacebook,
                                                  .postToTencentWeibo, .postToTwitter, .postToWeibo]
        self.present(activityViewCtrl, animated: true, completion: nil)
        
//        self.toastMessage(title: "Waiting...")
    }
    
}
