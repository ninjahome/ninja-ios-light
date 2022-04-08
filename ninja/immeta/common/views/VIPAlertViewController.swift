//
//  VIPAlertViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/1/6.
//

import UIKit

class VIPAlertViewController: UIViewController {

        override func viewDidLoad() {
                super.viewDidLoad()
        }
        
        @IBAction func CloseWindow(_ sender: UIButton) {
                self.dismiss(animated: true)
        }
}
