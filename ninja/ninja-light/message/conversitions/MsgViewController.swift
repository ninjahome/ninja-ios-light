//
//  MsgViewController.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit
import AVFoundation
import MobileCoreServices

class MsgViewController: UIViewController, UIGestureRecognizerDelegate {
        
        @IBOutlet weak var voiceBtn: UIButton!
        @IBOutlet weak var sender: UITextView!
        @IBOutlet weak var recordBtn: UIButton!
    
        @IBOutlet weak var vipView: UIView!
        @IBOutlet weak var mutiMsgType: UIView!
        
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
        
        @IBOutlet weak var voiceVipImg: UIImageView!
        @IBOutlet weak var cameraVipImg: UIImageView!
        @IBOutlet weak var imageVipimg: UIImageView!
        @IBOutlet weak var fileVipImg: UIImageView!
        
        var IS_GROUP: Bool = false

        var messages: [MessageItem] = []
        var isTextType = true

        var selectedRow: Int?
        var isLocalMsg:Bool?

        var keyboardIsHide: Bool = true

        let audioRecorder = AudioRecordManager.shared
        fileprivate var finishRecording = true

        var _delegate: UIGestureRecognizerDelegate?
    
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                populateView()
                DispatchQueue.main.async {
                        self.scrollToBottom()
                }

                if (self.navigationController?.viewControllers.count)! >= 1 {
                        _delegate = self.navigationController?.interactivePopGestureRecognizer?.delegate
                        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
                }

        }
        
        override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
                self.navigationController?.interactivePopGestureRecognizer?.delegate = _delegate

                AudioPlayManager.sharedInstance.playMusic(file: Data(), stop: true)
        }

        override func viewDidLoad() {
                super.viewDidLoad()
                audioRecorder.delegate = self
                messageTableView.delegate = self
                messageTableView.dataSource = self
                
                vipView.layer.contents = UIImage(named: "bgc")?.cgImage
                if Wallet.shared.liceneseExpireTime > 0 {
                        vipView.isHidden = true
                }
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

                senderBar.layer.shadowOpacity = 0.1

                if let msges = MessageItem.cache.get(idStr: self.peerUid) {
                        self.messages = msges
                }
        }

        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        func vipRelatedUI() {
                if Wallet.shared.isStillVip() {
                        voiceVipImg.isHidden = true
                        imageVipimg.isHidden = true
                        cameraVipImg.isHidden = true
                        fileVipImg.isHidden = true
                }
        }

        @IBAction func moreMsgType(_ sender: UIButton) {
                mutiMsgType.isHidden = false
        }

        @IBAction func cancelMutiType(_ sender: UIButton) {
                mutiMsgType.isHidden = true
        }

        @IBAction func camera(_ sender: UIButton) {
                if Wallet.shared.isStillVip() {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                let cameraPicker = UIImagePickerController()
                                cameraPicker.delegate = self
                                cameraPicker.allowsEditing = true
                                cameraPicker.sourceType = .camera
                                cameraPicker.mediaTypes = ["public.movie", "public.image"]
                                present(cameraPicker, animated: true, completion: nil)
                        } else {
                                toastMessage(title: "无相机访问权限")
                        }
                } else {
                        showVipModalViewController()
                }
        }
    
        @IBAction func album(_ sender: UIButton) {
                if Wallet.shared.isStillVip() {
                        let vc = UIImagePickerController()
                        vc.sourceType = .photoLibrary
                        vc.mediaTypes = ["public.movie", "public.image"]
                        vc.videoQuality = .typeMedium
                        vc.delegate = self
                        vc.allowsEditing = true
                        present(vc, animated: true, completion: nil)
                } else {
                        showVipModalViewController()
                }
        }
        
        @IBAction func file(_ sender: UIButton) {
                if Wallet.shared.isStillVip() {
                        let vc = UIDocumentPickerViewController(documentTypes: [kUTTypeMovie as String, kUTTypeImage as String, kUTTypeZipArchive as String, kUTTypePDF as String, kUTTypeText as String], in: .import)
                        vc.delegate = self
                        vc.allowsMultipleSelection = false
                        vc.shouldShowFileExtensions = true
                        present(vc, animated: true, completion: nil)
                } else {
                        showVipModalViewController()
                }
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
                        ChatItem.CachedChats.get(idStr: self.peerUid)?.resetUnread()
                }
        }
    
        @objc func keyboardWillShow(notification:NSNotification) {

                if !keyboardIsHide {
                        return
                }

                guard let userInfo = notification.userInfo else { return }
                guard let keyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                        return
                }
                var duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
                
                if duration == nil {
                        duration = 0.25
                }

                let keyboardTopYPosition = keyboardRect.height
                self.textFieldConstrain.constant = -keyboardTopYPosition
                self.msgTableConstrain.constant = 0

                UIView.animate(withDuration: duration!) {
                        self.scrollToBottom()
                }

        }
        
        @objc func keyboardWillHide(notification:NSNotification) {
                guard let userInfo = notification.userInfo else { return }
                var duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
                
                if duration == nil {
                        duration = 0.25
                }

                self.textFieldConstrain.constant = 4
                self.msgTableConstrain.constant = 0

                print("keyboardWillHide")
                UIView.animate(withDuration: duration!) {
                        self.scrollToBottom()
                }
        }
    
        @objc func keyboardDidShow(notification: NSNotification) {
                guard let userInfo = notification.userInfo else {
                        return
                }
                var duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
                if duration == nil {
                        duration = 0.25
                }
                
                self.keyboardIsHide = false
                print("keyboardDidShow")

//                UIView.animate(withDuration: duration!) {
//
//                }
        }

        @objc func keyboardDidHide(notification: NSNotification) {
                guard let userInfo = notification.userInfo else {
                        return
                }
                var duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
                
                if duration == nil {
                        duration = 0.25
                }
                
                self.keyboardIsHide = true
                print("keyboardDidHide")

        }

        @objc func contactUpdate(notification: NSNotification) {
                contactData = ContactItem.cache[peerUid]
                self.peerNickName.title = self.contactData?.alias ?? self.peerUid
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

                guard let msges = MessageItem.cache.get(idStr: self.peerUid) else {
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
                                let vc = instantiateViewController(vcID: "ContactDetailsVC") as! ContactDetailsViewController
                                vc.itemUID = peerUid
                                self.navigationController?.pushViewController(vc, animated: true)
//                                self.performSegue(withIdentifier: "EditContactDetailsSEG", sender: self)
                        } else {
                                let vc = instantiateViewController(vcID: "SearchDetailVC") as! SearchDetailViewController
                                vc.uid = peerUid
                                self.navigationController?.pushViewController(vc, animated: true)
//                                self.performSegue(withIdentifier: "ShowStrangerDetailSeg", sender: self)
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
                if Wallet.shared.isStillVip() {
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
                } else {
                        showVipModalViewController()
                }
        }

        private func populateView() {
                vipRelatedUI()
                if IS_GROUP {
                        groupData = GroupItem.cache[peerUid]
                        setPeerNick()
                } else {
                        contactData = ContactItem.cache[peerUid]
                        if let alias = contactData?.alias {
                                self.peerNickName.title = alias
                        } else {
                                let acc = AccountItem.GetAccount(peerUid)
                                self.peerNickName.title = acc?.NickName ?? peerUid
                        }
                }
        }
        
        fileprivate func setPeerNick() {
                var count: String = "?"
                if let memberCount = self.groupData?.memberIds?.count {
                        count = String(memberCount+1)
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
        
        @IBAction func vipGuideBtn(_ sender: UIButton) {
                showVipModalViewController()
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
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
    
        private func scrollToBottom(animated: Bool = false) {
                let rowCount = self.messageTableView.numberOfRows(inSection: 0)

                guard rowCount > 0 else {
                        return
                }

                self.messageTableView.reloadData()
                self.view.layoutIfNeeded()

                if rowCount > 1 {
                        let bottomIndexPath = IndexPath.init(row: rowCount - 1, section: 0)
                        self.messageTableView.scrollToRow(at: bottomIndexPath, at: .bottom, animated: animated)
                }
        }

        private func layoutToBottom(animated: Bool = false) {
                self.messageTableView.setContentOffset(CGPoint.init(x: 0, y: (self.messageTableView.contentSize.height-self.messageTableView.bounds.size.height)), animated: animated)
        }
    
        func sendAllTypeMessage(_ cliMsg: CliMessage, resend: Bool = false) {

                WebsocketSrv.shared.SendIMMsg(cliMsg: cliMsg, retry: resend) {
                        if let msges = MessageItem.cache.get(idStr: self.peerUid) {
                                self.messages = msges
                                self.messageTableView.reloadData()
                                self.scrollToBottom()
                        }
                } onCompletion: { success in
                        if !success {
                                MessageItem.resetSending(msgid: cliMsg.timestamp!, to: cliMsg.to!, success: success)
                                if let msges = MessageItem.cache.get(idStr: self.peerUid) {
                                        self.messages = msges
                                        self.messageTableView.reloadData()
                                        self.scrollToBottom()
                                }
                        }
                        
                }

        }

}
