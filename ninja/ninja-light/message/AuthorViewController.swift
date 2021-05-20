//
//  AuthorViewController.swift
//  ninja-light
//
//  Created by wesley on 2021/4/11.
//

import UIKit

class AuthorViewController: UIViewController {

        @IBOutlet weak var tips: UILabel!
        @IBOutlet weak var password: UITextField!
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.hideKeyboardWhenTappedAround()
                if #available(iOS 13.0, *) {
                        self.isModalInPresentation = true
                }
        }
        
        @IBAction func Auth(_ sender: Any) {
                guard let pwd = password.text else{
                        tips.text = "please input your password"
                        return
                }
                self.showIndicator(withTitle: "", and: "opening")
               
                DispatchQueue.global().async {
                        guard let err = Wallet.shared.Active(pwd) else{
                                DispatchQueue.main.async {
                                        self.hideIndicator()
                                        self.hideKeyboardWhenTappedAround()
                                        self.dismiss(animated: true)
                                }
                                return
                        }
                        DispatchQueue.main.async {
                                self.tips.text = err.localizedDescription
                                self.hideIndicator()
                                self.hideKeyboardWhenTappedAround()
                        }
                }
        }
        

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
