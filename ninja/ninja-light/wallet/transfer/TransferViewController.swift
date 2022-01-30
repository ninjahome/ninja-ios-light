//
//  TransferViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/27.
//

import UIKit

class TransferViewController: UIViewController, UIGestureRecognizerDelegate {
        
        var _delegate: UIGestureRecognizerDelegate?
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                
                if (self.navigationController?.viewControllers.count)! >= 1 {
                        _delegate = self.navigationController?.interactivePopGestureRecognizer?.delegate
                        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
                }
        }
        
        override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
                self.navigationController?.interactivePopGestureRecognizer?.delegate = _delegate
        }
        
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                
        }
        
        @IBAction func returnItem(_ sender: UIBarButtonItem) {
                self.navigationController?.popViewController(animated: true)
        }
        
        @IBAction func didTapView(_ sender: UITapGestureRecognizer) {
                self.performSegue(withIdentifier: "ShowAuthorByIDViewControllerSEG", sender: nil)
        }
}
