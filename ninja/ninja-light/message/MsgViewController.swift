//
//  MsgViewController.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit
import AVFoundation

class MsgViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
        
    @IBOutlet weak var voiceBtn: UIButton!
    @IBOutlet weak var sender: UITextView!
    @IBOutlet weak var recordBtn: UIButton!
    
    @IBOutlet weak var mutiMsgType: UIView!
    
//    @IBOutlet weak var receiver: UITextView!
    @IBOutlet weak var peerNickName: UINavigationItem!
    var peerUid:String = ""
    var contactData:ContactItem?
    
    
    @IBOutlet weak var recordSeconds: UILabel!
    @IBOutlet weak var recordingPoint: UIView!
    @IBOutlet weak var recordingTip: UILabel!
    
    
    @IBOutlet weak var senderBar: UIView!
    @IBOutlet weak var textFieldConstrain: NSLayoutConstraint!
    @IBOutlet weak var msgTableConstrain: NSLayoutConstraint!
    
    @IBOutlet weak var messageTableView: UITableView!
    
    var messages: [MessageItem]!
    var isTextType = true
    
    let audioRecorder = AudioRecordManager.shared
    fileprivate var finishRecording = true
    
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
        
                audioRecorder.delegate = self
        
                senderBar.layer.shadowOpacity = 0.1
                self.messages = msges
//                self.receiver.text = msges.toString()
                self.messageTableView.reloadData()
                DispatchQueue.main.async {
                    self.scrollToBottom()
                }
                
        }
    
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        guard WebsocketSrv.shared.IsOnline() else {
//
//            print("Msg connecting")
//                guard let err = WebsocketSrv.shared.Online() else{
//                        return
//                }
//                return
//        }
//        print("Msg connected")
//
//    }
        
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func moreMsgType(_ sender: UIButton) {
        mutiMsgType.isHidden = false
    }
    
    @IBAction func cancelMutiType(_ sender: UIButton) {
        mutiMsgType.isHidden = true
    }
    
    @IBAction func camera(_ sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let cameraPicker = UIImagePickerController()
            cameraPicker.delegate = self
            cameraPicker.allowsEditing = true
            cameraPicker.sourceType = .camera
            present(cameraPicker, animated: true, completion: nil)
        } else {
            toastMessage(title: "无相机访问权限")
        }
        
    }
    
    @IBAction func album(_ sender: UIButton) {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func location(_ sender: UIButton) {
    }
    
    
    @IBAction func cancelRecord(_ sender: Any) {
        
        print("touch up outside")
    }

    @IBAction func recordLongPress(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            
            print("press began")
            self.audioRecorder.checkPermissionAndInitRecord { onFaild in
                print("check permission and init record:\(onFaild)")
            }
            self.audioRecorder.startRecord()
            beganRecord()

        } else if sender.state == .changed {
            
            print("press changed")
            let point = sender.location(in: self.recordingPoint)
            if self.recordingPoint.point(inside: point, with: nil) {
                willCancelRecord()
            } else {
                showCancelRecord()
            }
            
        } else if sender.state == .ended {
            print("press end \(finishRecording)")
            if finishRecording {
                self.audioRecorder.stopRecord()
                
            } else {
                self.audioRecorder.cancelRecord()
            }
            endRecord()
            
        } else if sender.state == .cancelled {
            self.audioRecorder.stopRecord()
        }
        
    }
    
    func willCancelRecord() {
        finishRecording = false
        self.recordingPoint.layer.contents = UIImage(named: "voicecancel_icon")?.cgImage
        self.recordingTip.text = "松手取消发送"
    }
    
    func showCancelRecord() {
        finishRecording = true
        self.recordingPoint.layer.contents = UIImage(named: "voiceBG_icon")?.cgImage
        self.recordingTip.text = "上滑取消"
    }
    
    
    func beganRecord() {
        finishRecording = true
//        print("began. finishRecording \(finishRecording)")
        
        self.recordingPoint.isHidden = false
        self.recordingTip.isHidden = false
        self.recordBtn.setTitle("松开发送", for: .normal)
    }
    
    func endRecord() {
        self.recordingPoint.layer.contents = nil
        self.recordingTip.text = ""
        self.recordingPoint.isHidden = true
        self.recordingTip.isHidden = true
        self.recordBtn.setTitle("按住说话", for: .normal)
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
            self.msgTableConstrain.constant = 0
//            self.msgTableConstrain.constant = keyboardTopYPosition+30
            
            UIView.animate(withDuration: duration!) {
                self.view.setNeedsLayout()
                self.scrollToBottom()
            }
            messageTableView.setContentOffset(CGPoint(x: 0, y: CGFloat.greatestFiniteMagnitude), animated: true)
            
        }
        
        @objc func keyboardWillHide(notification:NSNotification) {
            guard let userInfo = notification.userInfo else { return }
            var duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
            if duration == nil {
                duration = 0.25
            }
            
            self.textFieldConstrain.constant = 4
            self.msgTableConstrain.constant = 0
//            self.msgTableConstrain.constant = 90.0

            UIView.animate(withDuration: duration!) {
                self.view.setNeedsLayout()
                self.scrollToBottom()
                
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
//                        self.receiver.text = msges.toString()
                        self.messageTableView.reloadData()
                        self.scrollToBottom(animated: true)
                }
        }
        @IBAction func EditContactInfo(_ sender: UIBarButtonItem) {
                self.performSegue(withIdentifier: "EditContactDetailsSEG", sender: self)
        }
        
        @IBAction func voiceBtn(_ sender: UIButton) {
            if isTextType {
                self.voiceBtn.setImage(UIImage(named: "key_icon"), for: .normal)
                self.sender.isHidden = true
                self.recordBtn.isHidden = false
                
                isTextType = false
            } else {
                self.voiceBtn.setImage(UIImage(named: "voice_icon"), for: .normal)
                self.sender.isHidden = false
                self.recordBtn.isHidden = true
                isTextType = true
            }
            
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
            
            if messages != nil && messages.count > 1 {
                let index = IndexPath(row: messages.count-1, section: 0)
                self.messageTableView.scrollToRow(at: index, at: .bottom, animated: animated)
   
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
            
            let msgItem = messages[indexPath.row]
            
            switch msgItem.typ {
            case .plainTxt:
                let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
                cell.updateMessageCell(by: messages[indexPath.row])
                return cell
            case .voice:
                let cell = tableView.dequeueReusableCell(withIdentifier: "voiceCell", for: indexPath) as! VoiceTableViewCell
                cell.updateMessageCell(by: messages[indexPath.row])
                return cell
            case .image:
                let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! ImageTableViewCell
                cell.updateMessageCell(by: messages[indexPath.row])
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
                cell.updateMessageCell(by: messages[indexPath.row])
                return cell
            }
        }
    
        func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
            return 50
        }
        
        func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return UITableView.automaticDimension
        }

}

extension MsgViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let img = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerOriginalImage")] as! UIImage
        var imagedata:Data?
        
        if img.jpeg != nil {
            imagedata = img.jpeg
        } else {
            imagedata = img.png
        }
        
        let cliMsg = CliMessage.init(to: peerUid, imgData: imagedata!)
        
        
        DispatchQueue.global().async {
            guard let err = WebsocketSrv.shared.SendIMMsg(cliMsg: cliMsg) else {
                if let msges = MessageItem.cache[self.peerUid] {
//                    DispatchQueue.main.async {
                        self.messages = msges
                        print("+++发送消息")
//                    }
                }
                return
            }
            DispatchQueue.main.async {
                print("+++发送成功 更新table view")
                    self.messageTableView.reloadData()
                    self.scrollToBottom()
                    self.toastMessage(title: err.localizedDescription)

            }
            
        }
//        DispatchQueue.main.async {
//            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
//            guard let err = WebsocketSrv.shared.SendIMMsg(cliMsg: cliMsg) else {
//                if let msges = MessageItem.cache[self.peerUid] {
//
//                    self.messages = msges
//                    self.messageTableView.reloadData()
//
//                    self.scrollToBottom()
//                }
//                return
//            }
//            self.toastMessage(title: err.localizedDescription)
//        }

    }
}

extension MsgViewController: UITextViewDelegate {
        
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            
        if (text == "\n") {
            guard let msg = self.sender.text, msg != "" else{
                    return false
            }
//                        let cliMsg = CliMessage.init(to:peerUid, data: msg)
            let cliMsg = CliMessage.init(to: peerUid, txtData: msg)
            guard let err = WebsocketSrv.shared.SendIMMsg(cliMsg: cliMsg) else{
                textView.text = nil
//                                receiver.insertText("[me]:" + msg + "\r\n")
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

extension MsgViewController: RecordAudioDelegate {
    func audioRecordUpdateMetra(_ metra: Float) {
        print("...update metra")
    }
    
    func audioRecordTooShort() {
        print("...record too short")
    }
    
    func audioRecordFailed() {
        print("...record failed")
    }
    
    func audioRecordCanceled() {
        print("...record canceled")
    }
    
    func audioRecordFinish(_ uploadAmrData: Data, recordTime: Float, fileHash: String) {
//        let cliMsg = CliMessage.init(to: peerUid, audioD: uploadAmrData, length: Int(recordTime))
//        guard let err = WebsocketSrv.shared.SendIMMsg(cliMsg: cliMsg) else {
//            if let msges = MessageItem.cache[self.peerUid] {
//
//                messages = msges
//                messageTableView.reloadData()
//
//                scrollToBottom()
//            }
//            return
//        }
//        self.toastMessage(title: err.localizedDescription)
        print("record finish")
    }
    
    func audioRecordWavFinish(_ uploadWavData: Data, recordTime: Float, fileHash: String) {
        let cliMsg = CliMessage.init(to: peerUid, audioD: uploadWavData, length: Int(recordTime))
        guard let err = WebsocketSrv.shared.SendIMMsg(cliMsg: cliMsg) else {
            if let msges = MessageItem.cache[self.peerUid] {
                
                messages = msges
                messageTableView.reloadData()
                
                scrollToBottom()
            }
            return
        }
        self.toastMessage(title: err.localizedDescription)

        print("record wav finish")
    }

}

//extension MsgViewController: UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        if touch.view is UIButton {
//            return false
//        }
//        return true
//    }
//}
