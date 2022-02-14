//
//  QRCodeShowViewController.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import UIKit

class QRCodeShowViewController: UIViewController {

        @IBOutlet weak var Image: UIImageView!
        public var QRImage:UIImage?

        override func viewDidLoad() {
                super.viewDidLoad()
                self.view.layer.cornerRadius = 16
                guard let image = QRImage else{
                        self.ShowTips(msg: NSLocalizedString("Empty data to show".locStr, comment: ""))
                        self.dismiss(animated: true)
                        return
                }
                Image.image = image
        }
        
        @IBAction func CloseWindows(_ sender: Any) {
                self.dismiss(animated: true)
        }
}
