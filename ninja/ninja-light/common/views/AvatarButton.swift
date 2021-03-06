//
//  AvatarButton.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/9/7.
//

import UIKit
import CloudKit

class AvatarButton: UIButton {
        var peerID:String = ""
        var showDetails:Bool = false
        func setup(id: String, avaData: Data?, showDetails:Bool = true){
                self.peerID = id
                let backImg = MustImage(data: avaData)
                self.setBackgroundImage(backImg, for: .normal)
                self.layer.masksToBounds = true
                self.showDetails = showDetails
        }
        
        func setupSelf(){
                self.showDetails = false
                let backImg = MustImage(data:  Wallet.shared.avatarData)
                self.setBackgroundImage(backImg, for: .normal)
                self.layer.masksToBounds = true
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
                super.touchesEnded(touches, with: event)
                if !showDetails{
                        return
                }
                if let _ = CombineConntact.cache[peerID] {
                        let vc = instantiateViewController(storyboardName: "Main", viewControllerIdentifier: "ContactDetailsVC") as! ContactDetailsViewController
                        vc.peerID = peerID
                        UIViewController.topMostInApp?.navigationController?.pushViewController(vc, animated: true)
                } else {
                        let vc = instantiateViewController(storyboardName: "Main", viewControllerIdentifier: "SearchDetailVC") as! SearchDetailViewController
                        vc.uid = peerID
                        UIViewController.topMostInApp?.navigationController?.pushViewController(vc, animated: true)
                }
        }
}
