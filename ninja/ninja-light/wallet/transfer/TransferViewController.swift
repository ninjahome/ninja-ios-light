//
//  TransferViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/27.
//

import UIKit

class TransferViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    @IBAction func returnItem(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }

}
