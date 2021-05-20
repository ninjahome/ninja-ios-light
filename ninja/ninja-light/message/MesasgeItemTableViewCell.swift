//
//  MesasgeItemTableViewCell.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import UIKit

class MesasgeItemTableViewCell: UITableViewCell {

        @IBOutlet weak var unreadView: UIView!
        @IBOutlet weak var unread: UILabel!
        @IBOutlet weak var avatarImg: UIImageView!
        @IBOutlet weak var nickName: UILabel!
        @IBOutlet weak var LastMsg: UILabel!
        
        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }

        func initWith(details:ChatItem, idx:Int){
                if details.ImageData != nil{
                        self.avatarImg.image = UIImage.init(data: details.ImageData!)
                }else{
                        //Deault image associate with account id
                }
                self.nickName.text = details.NickName
                self.LastMsg.text = details.LastMsg
                if details.unreadNo > 0{
                        self.unread.text = "\(details.unreadNo)"
                        self.unreadView.isHidden = false
                }else{
                        self.unreadView.isHidden = true
                        self.unread.text = ""
                }
                
        }
}
