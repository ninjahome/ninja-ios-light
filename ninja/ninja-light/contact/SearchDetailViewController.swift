//
//  SearchDetailViewController.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/7/8.
//

import UIKit

class SearchDetailViewController: UIViewController {

    
    @IBOutlet weak var backContent: UIView!
    @IBOutlet weak var avatar: UIButton!
    @IBOutlet weak var uidText: UILabel!
        
    var uid: String?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)
 
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        uidText.text = uid
        
        let avatarText = (uid?.prefix(2))!
        avatar.setTitle(String(avatarText), for: .normal)
        
        backContent.layer.contents = UIImage(named: "user_backg_img")?.cgImage
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @IBAction func backBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
