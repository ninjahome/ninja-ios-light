//
//  MsgViewController.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit

class MsgViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
        @IBOutlet weak var sender: UITextView!
        @IBOutlet weak var receiver: UITextView!
        @IBOutlet weak var peerNickName: UINavigationItem!
        var peerUid:String = ""
        var contactData:ContactItem?
        
    @IBOutlet weak var senderBar: UIView!
    @IBOutlet weak var textFieldConstrain: NSLayoutConstraint!
    @IBOutlet weak var msgTableConstrain: NSLayoutConstraint!
    
    @IBOutlet weak var messageTableView: UITableView!
    
    var messages: [MessageItem]!
    
    
    override func viewDidLoad() {
                super.viewDidLoad()
        
                messageTableView.delegate = self
                messageTableView.dataSource = self
        
                self.hideKeyboardWhenTappedAround()
                self.populateView()
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(newMsg(notification:)),
                                                       name: NotifyMessageAdded,
                                                       object: nil)
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(contactUpdate(notification:)),
                                                       name: NotifyContactChanged,
                                                       object: nil)
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(keyboardWillShow(notification:)),
                                                       name: UIResponder.keyboardWillShowNotification,
                                                       object: nil)
                NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillHide(notification:)),
                                                   name: UIResponder.keyboardWillHideNotification,
                                                   object: nil)
                
        
        
                guard let msges = MessageItem.cache[self.peerUid] else{
                        return
                }
                self.messages = msges
                self.receiver.text = msges.toString()
                self.messageTableView.reloadData()
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        override func viewDidDisappear(_ animated: Bool) {
                super.viewDidDisappear(animated)
            
                ServiceDelegate.workQueue.async {
                        ChatItem.CachedChats[self.peerUid]?.resetUnread()
//                        MessageItem.removeRead(self.peerUid)
                }
        }
        
        @objc func keyboardWillShow(notification:NSNotification) {
            guard let userInfo = notification.userInfo else { return }
            guard let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else{return}
            var duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
            if duration == nil {
                duration = 0.25
            }
            
            let keyboardTopYPosition = keyboardRect.height
            self.textFieldConstrain.constant = -keyboardTopYPosition
            self.msgTableConstrain.constant = keyboardTopYPosition+60
            
            UIView.animate(withDuration: duration!) {
                self.view.setNeedsLayout()
            }
            self.scrollToBottom()
            
        }
        
        @objc func keyboardWillHide(notification:NSNotification) {
            guard let userInfo = notification.userInfo else { return }
            var duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
            if duration == nil {
                duration = 0.25
            }
            
            self.textFieldConstrain.constant = -60.0
            self.msgTableConstrain.constant = 90.0

            UIView.animate(withDuration: duration!) {
                self.view.setNeedsLayout()
            }

            
        }

        @objc func contactUpdate(notification:NSNotification){
                contactData = ContactItem.cache[peerUid]
                DispatchQueue.main.async {
                        self.peerNickName.title = self.contactData?.nickName ?? self.peerUid
                }
        }
        @objc func newMsg(notification:NSNotification){
                guard let uid = notification.userInfo?[MessageItem.NotiKey] as? String else {
                        return
                }
                
                if uid != self.peerUid{
                        return
                }
                
                guard let msges = MessageItem.cache[self.peerUid] else{
                        return
                }

                DispatchQueue.main.async {
                        self.messages = msges
                        self.receiver.text = msges.toString()
                        self.messageTableView.reloadData()
                        self.scrollToBottom(animated: true)
                }
        }
        @IBAction func EditContactInfo(_ sender: UIBarButtonItem) {
                self.performSegue(withIdentifier: "EditContactDetailsSEG", sender: self)
        }
        
        private func populateView(){
                contactData = ContactItem.cache[peerUid]
                self.peerNickName.title = contactData?.nickName ?? peerUid
        }
    
        // MARK: - Navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "EditContactDetailsSEG"{
                        let vc : ContactDetailsViewController = segue.destination as! ContactDetailsViewController
                        vc.itemUID = peerUid
                }
        }
    
        func scrollToBottom(animated: Bool = false) {
            if messages != nil {
                messageTableView.scrollToRow(at: IndexPath(row: messages.count-1, section: 0), at: .bottom, animated: animated)
            }
        }
    
        //MARK: - TableViewDelegates
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if messages != nil {
                return messages.count
            }
            return 0
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
            cell.updateMessageCell(by: messages[indexPath.row])
            return cell
        }
    
        func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
            return 50
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return UITableView.automaticDimension
        }
//
//        func numberOfSections(in tableView: UITableView) -> Int {
//            return 1
//        }

}

extension MsgViewController: UITextViewDelegate {
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
                
                if (text == "\n"){
                        guard let msg = self.sender.text else{
                                return false
                        }
                        let cliMsg = CliMessage.init(to:peerUid, data: msg)
                        guard let err = WebsocketSrv.shared.SendIMMsg(cliMsg: cliMsg) else{
                                textView.text = nil
                                receiver.insertText("[me]:" + msg + "\r\n")
                            
                                if let msges = MessageItem.cache[self.peerUid] {
                                    messages = msges
                                    messageTableView.reloadData()
                                    
                                    scrollToBottom()
                                }
                            
                                return false
                        }
                        self.toastMessage(title: err.localizedDescription)
                        return false
                }
                return true
        }
}
