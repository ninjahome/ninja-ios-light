//
//  MsgViewController.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit
import AVFoundation

class MsgViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
        
    @IBOutlet weak var voiceBtn: UIButton!
    @IBOutlet weak var sender: UITextView!
    @IBOutlet weak var recordBtn: UIButton!
    
    @IBOutlet weak var mutiMsgType: UIView!

//    @IBOutlet weak var receiver: UITextView!
    @IBOutlet weak var peerNickName: UINavigationItem!
    var peerUid: String = ""
//    var groupId: String = ""
    
    var contactData:ContactItem?
    var groupData:GroupItem?
    
    @IBOutlet weak var recordSeconds: UILabel!
    @IBOutlet weak var recordingPoint: UIView!
    @IBOutlet weak var recordingTip: UILabel!
    
    
    @IBOutlet weak var senderBar: UIView!
    @IBOutlet weak var textFieldConstrain: NSLayoutConstraint!
    @IBOutlet weak var msgTableConstrain: NSLayoutConstraint!
    
    @IBOutlet weak var messageTableView: UITableView!
    
    var IS_GROUP: Bool = false
    
    var messages: [MessageItem]!
    var isTextType = true
//    var locationMessage: locationMsg?
    var selectedRow: Int?
    var isLocalMsg:Bool?
    
    var keyboardIsHide: Bool = true
    
    let audioRecorder = AudioRecordManager.shared
    fileprivate var finishRecording = true
    
    var _delegate: UIGestureRecognizerDelegate?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.populateView()
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

        messageTableView.delegate = self
        messageTableView.dataSource = self

        self.hideKeyboardWhenTappedAround()
        
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardDidShow(notification: )),
                                               name: UIResponder.keyboardDidShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                       selector: #selector(keyboardDidHide(notification:)),
                                       name: UIResponder.keyboardDidHideNotification,
                                       object: nil)

        
        guard let msges = MessageItem.cache[self.peerUid] else{
            return
        }
        self.messages = msges
        audioRecorder.delegate = self

        senderBar.layer.shadowOpacity = 0.1
        
        self.messageTableView.reloadData()
        
        DispatchQueue.main.async {
            self.scrollToBottom()
        }
                
    }
        
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
        self.isLocalMsg = false
        self.performSegue(withIdentifier: "ShowMapSeg", sender: self)
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
        
        if !keyboardIsHide {
            return
        }
        
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
//                self.view.setNeedsLayout()
//                self.scrollToBottom()
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
//                self.view.setNeedsLayout()
//                self.scrollToBottom()
            
        }
    }
    
    @objc func keyboardDidShow(notification: NSNotification) {
        guard let _ = notification.userInfo else {
            return
        }
        self.keyboardIsHide = false
    }

    @objc func keyboardDidHide(notification: NSNotification) {
        guard let _ = notification.userInfo else {
            return
        }
        self.keyboardIsHide = true
    }

    @objc func contactUpdate(notification: NSNotification){
        contactData = ContactItem.cache[peerUid]
//        DispatchQueue.main.async {
            self.peerNickName.title = self.contactData?.nickName ?? self.peerUid
//        }
    }
    // TODO: Update group member
    @objc func groupUpdate(notification: NSNotification) {
        groupData = GroupItem.cache[peerUid]
        
        self.setPeerNick()
        
    }
    @objc func newMsg(notification: NSNotification){
        guard let uid = notification.userInfo?[MessageItem.NotiKey] as? String else {
                return
        }
        
        if uid != self.peerUid {
                return
        }
        
        guard let msges = MessageItem.cache[self.peerUid] else{
                return
        }
        self.messages = msges
        
        DispatchQueue.main.async {
            self.messageTableView.reloadData()
            self.scrollToBottom(animated: true)
        }
    }
    
    @IBAction func EditContactInfo(_ sender: UIBarButtonItem) {
        if IS_GROUP {
            self.performSegue(withIdentifier: "ShowGroupDetailSeg", sender: self)
        } else {
            if isInContact() {
                self.performSegue(withIdentifier: "EditContactDetailsSEG", sender: self)
            } else {
                self.performSegue(withIdentifier: "ShowStrangerDetailSeg", sender: self)
            }
        }
    }
    
    @IBAction func BackToMsgList(_ sender: UIBarButtonItem) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    private func isInContact() -> Bool {
        
        if ContactItem.GetContact(peerUid) != nil {
            return true
        }
        return false
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
        if IS_GROUP {
            groupData = GroupItem.cache[peerUid]
            setPeerNick()
        } else {
            contactData = ContactItem.cache[peerUid]
            self.peerNickName.title = contactData?.nickName ?? peerUid
        }
    }
        
    fileprivate func setPeerNick() {
        var count: String = "?"
        if let memberCount = self.groupData?.memberIds?.count {
            count = String(memberCount)
        }
        self.peerNickName.title = "\(self.groupData?.groupName ?? "群聊")(\(count))"
    }
    
    @IBAction func locationBtn(_ sender: UIButton) {
        if let cell = sender.superview?.superview?.superview as? UITableViewCell {
            self.selectedRow = self.messageTableView.indexPath(for: cell)?.row
            self.isLocalMsg = true
        }
        
        self.performSegue(withIdentifier: "ShowMapSeg", sender: self)
    }

        // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditContactDetailsSEG"{
            let vc : ContactDetailsViewController = segue.destination as! ContactDetailsViewController
            vc.itemUID = peerUid
        }
        if segue.identifier == "ShowStrangerDetailSeg" {
            let vc:SearchDetailViewController = segue.destination as! SearchDetailViewController
            vc.uid = peerUid
        }

        if segue.identifier == "ShowMapSeg" {
            let vc: MapViewController = segue.destination as! MapViewController
            vc.delegate = self
            
            if isLocalMsg!, let idx = self.selectedRow {
                vc.isMsg = true
                
                let msg:MessageItem = messages[idx]
                vc.sendMsg = msg
            } else {
                vc.isMsg = false
            }
            
        }
        
        if segue.identifier == "ShowGroupDetailSeg" {
            let vc: GroupDetailViewController = segue.destination as! GroupDetailViewController
            vc.groupItem = self.groupData
            
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
        var identifer = ""
        
        switch msgItem.typ {
        case .plainTxt:
            identifer = msgItem.isOut ? "messageCell" : "messageCellL"
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! MessageTableViewCell
            cell.updateMessageCell(by: msgItem)
            return cell
        case .voice:
            identifer = msgItem.isOut ? "voiceCell" : "voiceCellL"
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! VoiceTableViewCell
            cell.updateMessageCell(by: msgItem)
            return cell
        case .image:
            identifer = msgItem.isOut ? "imageCell" : "imageCellL"
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! ImageTableViewCell
            cell.updateMessageCell(by: msgItem)
            return cell
        case .location:
            identifer = msgItem.isOut ? "locationCell" : "locationCellL"
            
            let cell = tableView.dequeueReusableCell(withIdentifier: identifer, for: indexPath) as! LocationTableViewCell
            cell.updateMessageCell(by: msgItem)
            return cell
        default:
//                let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! MessageTableViewCell
//                cell.updateMessageCell(by: messages[indexPath.row])
            return MessageTableViewCell()
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
//        let img = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerOriginalImage")] as! UIImage
        let img = info[.originalImage] as! UIImage

        var imagedata:Data?
        
        if img.jpeg != nil {
            imagedata = img.jpeg
        } else {
            imagedata = img.png
        }
        
        let cliMsg = CliMessage.init()
        if IS_GROUP {
        
            guard let group = groupData,
                  let ids = group.memberIds as? [String] else {
                return
            }
            cliMsg.to = ids.toString()
            cliMsg.groupId = peerUid
            cliMsg.imgData = imagedata
        } else {
            cliMsg.to = peerUid
            cliMsg.imgData = imagedata
        }
        cliMsg.type = .image
//        WebsocketSrv.messageQueue.async {
            print("+++发送消息")
            guard let err = WebsocketSrv.shared.SendIMMsg(cliMsg: cliMsg) else {
                if let msges = MessageItem.cache[self.peerUid] {
                    print("+++发送消息成功")
//                    DispatchQueue.main.async {
                        print("+++发送成功 更新table view")
                        self.messages = msges
                        self.messageTableView.reloadData()
                        self.scrollToBottom()
//                    }
                }
                return
            }
//            DispatchQueue.main.async {
                print("+++发送失败")
                self.toastMessage(title: err.localizedDescription)
//            }
//        }
    }
}

extension MsgViewController: MapViewControllerDelegate {
    func sendLocation(location: locationMsg) {
        print("send location msg:\(location.la)\(location.lo)\(location.str)")
        let cliMsg = CliMessage.init()
        if IS_GROUP {
            cliMsg.groupId = self.peerUid
            guard let group = groupData,
                  let ids = group.memberIds as? [String] else {
                return
            }
            cliMsg.to = ids.toString()
            cliMsg.locationData = location
            
        } else {
            cliMsg.to = peerUid
            cliMsg.locationData = location
        }
        cliMsg.type = .location
//        let cliMsg = CliMessage.init(to: peerUid, locationData: location, groupId: groupId)
        guard let err = WebsocketSrv.shared.SendIMMsg(cliMsg: cliMsg) else {
            if let msges = MessageItem.cache[self.peerUid] {
                messages = msges
                messageTableView.reloadData()
                scrollToBottom()
            }
            return
        }
        
        self.toastMessage(title: err.localizedDescription)
    }
}

extension MsgViewController: UITextViewDelegate {
        
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            
        if (text == "\n") {
            guard let msg = self.sender.text, msg != "" else {
                    return false
            }
            let cliMsg = CliMessage.init()
            cliMsg.type = .plainTxt
            if IS_GROUP {
                cliMsg.groupId = self.peerUid
                guard let group = groupData,
                      let ids = group.memberIds as? [String] else {
                    self.toastMessage(title: "Can not find group info")
                    return false
                }
                cliMsg.to = ids.toString()
                cliMsg.textData = msg
                
            } else {
                cliMsg.to = peerUid
                cliMsg.textData = msg
            }

            
//            let cliMsg = CliMessage.init(to: peerUid, txtData: msg, groupId: groupId)
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
        print("\(metra)")
    }
    
    func audioRecordTooShort() {
        self.toastMessage(title: "Record too short")
    }
    
    func audioRecordFailed() {
        self.toastMessage(title: "Record failed")
    }
    
    func audioRecordCanceled() {
        print("Record canceled")
    }
    
    func audioRecordFinish(_ uploadAmrData: Data, recordTime: Float, fileHash: String) {
        print("Record finished")
    }
    
    func audioRecordWavFinish(_ uploadWavData: Data, recordTime: Float, fileHash: String) {
        if recordTime < 1 {
            self.toastMessage(title: "Record too short")
            return
        }
        let cliMsg = CliMessage.init()
        cliMsg.type = .voice
        if IS_GROUP {
            cliMsg.groupId = self.peerUid
            guard let group = groupData,
                  let ids = group.memberIds as? [String] else {
                return
            }
            cliMsg.to = ids.toString()
        } else {
            cliMsg.to = peerUid
        }
        let audio: audioMsg = audioMsg.init()
        audio.content = uploadWavData
        audio.duration = Int(recordTime)
        cliMsg.audioData = audio
        
//        let cliMsg = CliMessage.init(to: peerUid, audioD: uploadWavData, length: Int(recordTime), groupId: groupId)
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
