//
//  NewContactViewController.swift
//  ninja-light
//
//  Created by hyperorchid on 2021/4/8.
//

import UIKit

class ContactDetailsViewController: UIViewController, UIGestureRecognizerDelegate {
        
        @IBOutlet weak var backContent: UIView!
        @IBOutlet weak var avator: AvatarButton!
        @IBOutlet weak var nickName: UILabel!
        @IBOutlet weak var uid: UILabel!
        @IBOutlet weak var deleteBtn: UIButton!
        @IBOutlet weak var moreBtn: UIButton!
        @IBOutlet weak var vipFlagImgView: UIImageView!
        @IBOutlet weak var nickTextField: UITextField!
        @IBOutlet weak var memoTextView: UITextView!
        
        var peerID:String = ""
        var contactData:CombineConntact?
        var _delegate: UIGestureRecognizerDelegate?
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                
                self.vipFlagImgView.isHidden = Wallet.shared.isStillVip()
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                
                if (self.navigationController?.viewControllers.count)! >= 1 {
                        _delegate = self.navigationController?.interactivePopGestureRecognizer?.delegate
                        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
                }
        }
        
        override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.navigationController?.interactivePopGestureRecognizer?.delegate = _delegate
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
                self.hideKeyboardWhenTappedAround()
                
                self.showIndicator(withTitle: "waiting", and: "loading contact")
                
                ServiceDelegate.workQueue.async {
                        
                        guard let data = CombineConntact.fetchContactFromChain(pid: self.peerID)else{
                                self.hideIndicator()
                                return
                        }
                        
                        self.contactData = data
                        CombineConntact.cache[self.peerID] = data
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                        object: nil, userInfo:nil)
                        DispatchQueue.main.async {
                                self.hideIndicator()
                                self.populateView()
                        }
                }
                
                self.populateView()
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @IBAction func backBtn(_ sender: UIButton) {
                self.navigationController?.popToRootViewController(animated: true)
        }
        
        @IBAction func saveChanges(_ sender: UIButton) {
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                
                guard let obj = self.contactData else{
                        self.toastMessage(title: "no valid contact data")
                        return
                }
                
                self.showIndicator(withTitle: "waiting", and: "saving contact")
                let alias = self.nickTextField.text
                let remark = self.memoTextView.text
                ServiceDelegate.workQueue.async {
                        let err = obj.updateByUI(alias: alias, remark:  remark)
                        self.closeOrShowErrorTips(err:err)
                }
        }
        
        @IBAction func moreBarItem(_ sender: UIButton) {
                if !Wallet.shared.isStillVip(){
                        showVipModalViewController()
                        return
                }
                
                if deleteBtn.isHidden {
                        deleteBtn.isHidden = false
                        moreBtn.setImage(UIImage(named: "x_icon"), for: .normal)
                } else {
                        deleteBtn.isHidden = true
                        moreBtn.setImage(UIImage(named: "more_icon"), for: .normal)
                }
        }
        
        @IBAction func deleteContact(_ sender: UIButton) {
                guard let obj = self.contactData else{
                        self.toastMessage(title: "no valid contact data")
                        return
                }
                
                self.showIndicator(withTitle: "waiting", and: "deleting contact")
                ServiceDelegate.workQueue.async {
                        let err =  obj.removeFromChain()
                        self.closeOrShowErrorTips(err:err)
                }
        }
        
        @IBAction func copyContactAddr(_ sender: UIButton) {
                UIPasteboard.general.string = self.peerID
                self.toastMessage(title: "Copy Success")
        }
        
        @IBAction func contactQRAlert(_ sender: UIButton) {
                ShowQRAlertView(data: self.peerID)
        }
        
        private func populateView() {
                self.uid.text = self.peerID
                guard let data = self.contactData else {
                        return
                }
                self.nickName.text = data.account?.NickName
                nickTextField.text = data.contact?.alias
                memoTextView.text = data.contact?.remark
                backContent.layer.contents = UIImage(named: "user_backg_img")?.cgImage
                
                avator.type = AvatarButtonType.chatContact
                avator.avaInfo = AvatarInfo.init(id: self.peerID, avaData: contactData?.account?.Avatar)
        }
        
        private func closeOrShowErrorTips(err:NJError?) {DispatchQueue.main.async {
                self.hideIndicator()
                
                guard let e = err else{
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                        object: nil, userInfo:nil)
                        self.dismiss(animated: true)
                        self.navigationController?.popViewController(animated: true)
                        return
                }
                self.ShowTips(msg: e.localizedDescription ?? "operation failed")
        }
        }
        
        @IBAction func StartChat(_ sender: UIButton) {
                guard let peerid = self.uid.text else{
                        return
                }
                let vc = instantiateViewController(vcID: "MsgVC") as! MsgViewController
                vc.peerUid = peerid
                
                self.navigationController?.pushViewController(vc, animated: true)
        }
}
