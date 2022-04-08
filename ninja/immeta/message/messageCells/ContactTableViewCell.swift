//
//  ContactTableViewCell.swift
//  immeta
//
//  Created by 郭晓芙 on 2022/3/3.
//

import UIKit

class ContactTableViewCell: UITableViewCell {
        @IBOutlet weak var msgBackgroundView: UIImageView!
        @IBOutlet weak var avatar: AvatarButton!
        @IBOutlet weak var nickname: UILabel!
        @IBOutlet weak var time: UILabel!
        @IBOutlet weak var retry: UIButton?
        @IBOutlet weak var spinner: UIActivityIndicatorView?
//        @IBOutlet weak var miniMapTrailing: NSLayoutConstraint!
//        @IBOutlet weak var miniMapLeading: NSLayoutConstraint!
        @IBOutlet weak var contactAvatar: UIButton!
        @IBOutlet weak var contactNick: UILabel!
        @IBOutlet weak var contactAddr: UILabel!
        
        var curMsg:MessageItem?
        var curViewCtrl: UIViewController?
        override func prepareForReuse() {
                super.prepareForReuse()
        }
        override func awakeFromNib() {
                super.awakeFromNib()
        }

        override func setSelected(_ selected: Bool, animated: Bool) {
                super.setSelected(selected, animated: animated)
        }
        
        @IBAction func resendFailedMsg(_ sender: Any) {
                guard let msg = self.curMsg else{
                        print("------>>>no valid msg in current cell")
                        return
                }
                msg.status = .sending
                spinner?.startAnimating()
                retry?.isHidden = true
                if let err = WebsocketSrv.shared.SendMessage(msg: msg){
                        print("------>>> retry failed:=>", err)
                        msg.status = .faild
                        retry?.isHidden = false
                        spinner?.stopAnimating()
                }
        }
        
        @objc func contactDetail(_ sender: UITapGestureRecognizer) {
                guard let contactmsg = curMsg?.payload as? contactMsg else {
                        return
                }

                guard let _ = CombineConntact.cache[contactmsg.uid] else {
//                        self.performSegue(withIdentifier: "SearchNewSegue", sender: self)
                        let vc = instantiateViewController(vcID: "SearchDetailVC") as! SearchDetailViewController
                        vc.uid = contactmsg.uid
                        curViewCtrl?.navigationController?.pushViewController(vc, animated: true)
                        return
                }
                
                let vc = instantiateViewController(vcID: "ContactDetailsVC") as! ContactDetailsViewController
                vc.peerID = contactmsg.uid
                curViewCtrl?.navigationController?.pushViewController(vc, animated: true)
        }
        
        func updateContactCell (by message: MessageItem, name:String, avatar:Data?, isGroup:Bool, viewCtrl: UIViewController) {
                self.curMsg = message
                self.curViewCtrl = viewCtrl
                let from = message.from
                
                msgBackgroundView.layer.cornerRadius = 8
                msgBackgroundView.clipsToBounds = true

                
                if let contMsg = message.payload as? contactMsg {
                        let (name, avatar) = ServiceDelegate.queryNickAndAvatar(pid: contMsg.uid) { name, avatar in
                                DispatchQueue.main.async {
//                                        self.contactAddr.text = contMsg.uid
                                        self.contactNick.text = name
                                        self.contactAvatar.setImage(MustImage(data: avatar), for: .normal)
                                }
                        }
                        self.contactAddr.text = contMsg.uid
                        self.contactNick.text = name
                        self.contactAvatar.setImage(MustImage(data: avatar), for: .normal)
                }
                //message bubble
                if message.isOut {
//                        let img = UIImage(named: "white")?.resizableImage(withCapInsets: UIEdgeInsets(top: 10, left: 12, bottom: 20, right: 12), resizingMode: .stretch)
//                        msgBackgroundView.image = img
//                        miniMapTrailing.constant = 8
                        
                        self.avatar.setupSelf()
                        switch message.status {
                        case .faild:
                                spinner?.stopAnimating()
                                retry?.isHidden = false
                        case .sending:
                                spinner?.startAnimating()
                        default:
                                spinner?.stopAnimating()
                        }
                        nickname.text = ""
                } else {
//                        let img = UIImage(named: "babycolor")?.resizableImage(withCapInsets: UIEdgeInsets(top: 10, left: 12, bottom: 20, right: 12), resizingMode: .stretch)
//                        msgBackgroundView.image = img
//                        miniMapLeading.constant = 8
                        
                        PopulatePeerCell(nickname:self.nickname,
                                         avatarBtn: self.avatar,
                                         from: from, name: name, avatar: avatar, isGroup: isGroup)
                }
                
                time.text = formatMsgTimeStamp(by: message.timeStamp)
                
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(contactDetail(_:)))
                msgBackgroundView.addGestureRecognizer(tapGestureRecognizer)
        }

}

extension UITableViewCell {
        func getCurrentViewController() -> UIViewController? {
                let window = getKeyWindow()
                let navCrtl = window?.rootViewController
                if let navigation = navCrtl as? UINavigationController {
                        return navigation.topViewController
                }
                return nil
        }

}

