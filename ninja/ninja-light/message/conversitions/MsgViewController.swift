//
//  MsgViewController.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit
import AVFoundation
import MobileCoreServices
import PhotosUI

class MsgViewController: UIViewController, UIGestureRecognizerDelegate {
        
        @IBOutlet weak var voiceBtn: UIButton!
        @IBOutlet weak var sender: UITextView!
        @IBOutlet weak var recordBtn: UIButton!
        
        @IBOutlet weak var vipView: UIView!
        @IBOutlet weak var mutiMsgType: UIView!
        
        @IBOutlet weak var peerNickName: UINavigationItem!
        
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
        var peerUid: String = ""
        var peerAvatarData:Data?
        var peerName:String=""
        var msgCacheArray: [MessageItem] = []
        var indexPathCache:[Int64:IndexPath] = [:]
        
        var isTextType = true
        var selectedRow: Int?
        var isLocalMsg:Bool?
        
        var recordCancelled:Bool = false
        var keyboardIsHide: Bool = true
        var refreshControl = UIRefreshControl()
        
        var _delegate: UIGestureRecognizerDelegate?
        
        override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                ChatItem.CurrentPID = peerUid
               
                if (self.navigationController?.viewControllers.count)! >= 1 {
                        _delegate = self.navigationController?.interactivePopGestureRecognizer?.delegate
                        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
                }
        }
        
        override func viewDidAppear(_ animated: Bool) {
                super.viewDidAppear(animated)
        }
        
        override func viewWillDisappear(_ animated: Bool) {
                super.viewWillDisappear(animated)
                self.navigationController?.interactivePopGestureRecognizer?.delegate = _delegate
                ChatItem.CurrentPID = ""
                AudioPlayManager.shared.stopPlay()
                CDManager.shared.saveContext()
        }
        
        override func viewDidLoad() {
                super.viewDidLoad()
                
                AudioRecordManager.shared.delegate = self
                messageTableView.delegate = self
                messageTableView.dataSource = self
                
                self.msgCacheArray = MessageItem.SortedArray(pid: self.peerUid)
                populateView()
                refreshControl.addTarget(self, action: #selector(loadMoreMsg(_:)), for: .valueChanged)
                messageTableView.addSubview(refreshControl)
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(newMsg(notification:)),
                                                       name: NotifyMessageAdded,
                                                       object: nil)
                
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(msgResult(notification:)),
                                                       name: NotifyMessageSendResult,
                                                       object: nil)
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(contactUpdate(notification:)),
                                                       name: NotifyContactChanged,
                                                       object: nil)
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(contactUpdate(notification:)),
                                                       name: NotifyGroupChanged,
                                                       object: nil)
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(peerNameUpdate(notification:)),
                                                       name: NotifyGroupNameOrAvatarChanged,
                                                       object: nil)
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(peerNameUpdate(notification:)),
                                                       name: NotifyGroupMemberChanged,
                                                       object: nil)
                NotificationCenter.default.addObserver(self,
                                                       selector:#selector(currentGroupDismiessed(notification:)),
                                                       name: NotifyGroupDeleteChanged,
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
                
        }
        
        deinit {
                NotificationCenter.default.removeObserver(self)
        }
        
        @objc func loadMoreMsg(_ sender: Any?) {
                let msg = msgCacheArray[0]
                guard let list = MessageItem.loadHistoryByPid2(pid: peerUid, timeStamp: msg.timeStamp) else {
                        return
                }
                msgCacheArray.insert(contentsOf: list, at: 0)
                self.refreshControl.endRefreshing()
                self.messageTableView.reloadData()
                
        }
        
        private func populateView() {
                self.setPeerBasic()
                vipView.layer.contents = UIImage(named: "bgc")?.cgImage
                senderBar.layer.shadowOpacity = 0.1
                
                self.hideKeyboardWhenTappedAround()
                
                if Wallet.shared.isStillVip() {
                        voiceVipImg.isHidden = true
                        imageVipimg.isHidden = true
                        cameraVipImg.isHidden = true
                        fileVipImg.isHidden = true
                        vipView.isHidden = true
                }
                
                self.scrollToBottom()
        }
        
        @IBAction func moreMsgType(_ sender: UIButton) {
                mutiMsgType.isHidden = false
        }
        
        @IBAction func cancelMutiType(_ sender: UIButton) {
                mutiMsgType.isHidden = true
        }
        
        @IBAction func EditContactInfo(_ sender: UIBarButtonItem) {
                if IS_GROUP {
                        self.performSegue(withIdentifier: "ShowGroupDetailSeg", sender: self)
                } else {
                        if isInContact() {
                                let vc = instantiateViewController(vcID: "ContactDetailsVC") as! ContactDetailsViewController
                                vc.peerID = peerUid
                                self.navigationController?.pushViewController(vc, animated: true)
                        } else {
                                let vc = instantiateViewController(vcID: "SearchDetailVC") as! SearchDetailViewController
                                vc.uid = peerUid
                                self.navigationController?.pushViewController(vc, animated: true)
                        }
                }
        }
        
        @IBAction func BackToMsgList(_ sender: UIBarButtonItem) {
                //                self.navigationController?.popViewController(animated: true)
                self.navigationController?.popToRootViewController(animated: true)
        }
        
        private func isInContact() -> Bool {
                return CombineConntact.cache[peerUid] != nil
        }
        
        private func setPeerBasic() {
                if IS_GROUP {
                        guard let groupData = GroupItem.cache[peerUid] else{
                                print("------>>> invalid group infos for current chat window")
                                self.navigationController?.popToRootViewController(animated: true)
                                return
                        }
                        
                        let count =  groupData.memberIds.count
                        if let n = groupData.groupName, !n.isEmpty{
                                self.peerNickName.title = "(\(count)) \(n)"
                        }else{
                                self.peerNickName.title = "(\(count)) \(peerUid)"
                        }
                        return
                }
                
                let (name, avatar) = ServiceDelegate.queryNickAndAvatar(pid: peerUid) { name, avatar in
                        
                        DispatchQueue.main.async {
                                self.initPeerUI(name: name, avatar: avatar)
                                self.messageTableView.reloadData()
                        }
                        
                }
                initPeerUI(name: name, avatar: avatar)
        }
        private func initPeerUI(name:String?, avatar:Data?){
                if let n = name, !n.isEmpty{
                        self.peerName = n
                }else{
                        self.peerName = self.peerUid
                }
                
                self.peerAvatarData =  avatar
                self.peerNickName.title = self.peerName
        }
        
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == "ShowMapSeg" {
                        let vc: MapViewController = segue.destination as! MapViewController
                        vc.delegate = self
                        
                        if isLocalMsg!, let idx = self.selectedRow {
                                vc.isMsg = true
                                
                                let msg:MessageItem = msgCacheArray[idx]
                                vc.sendMsg = msg
                        } else {
                                vc.isMsg = false
                        }
                }
                
                if segue.identifier == "ShowGroupDetailSeg" {
                        let vc: GroupDetailViewController = segue.destination as! GroupDetailViewController
                        vc.groupID =  peerUid
                }
                
        }
}

extension MsgViewController{
        
        @IBAction func locationBtn(_ sender: UIButton) {
                if let cell = sender.superview?.superview?.superview as? UITableViewCell {
                        self.selectedRow = self.messageTableView.indexPath(for: cell)?.row
                        self.isLocalMsg = true
                }
                
                self.performSegue(withIdentifier: "ShowMapSeg", sender: self)
        }
        
        @IBAction func camera(_ sender: UIButton) {
                guard Wallet.shared.isStillVip() else {
                        showVipModalViewController()
                        return
                }
                
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        let cameraPicker = UIImagePickerController()
                        cameraPicker.delegate = self
                        cameraPicker.allowsEditing = false
                        cameraPicker.sourceType = .camera
                        cameraPicker.mediaTypes = ["public.movie", "public.image"]
                        cameraPicker.videoMaximumDuration = 30
                        present(cameraPicker, animated: true, completion: nil)
                } else {
                        toastMessage(title: "No Camera Permission".locStr)
                }
        }
        private func accessPhoto(){ DispatchQueue.main.async {
                
                let photoLibrary = PHPhotoLibrary.shared()
                var configuration = PHPickerConfiguration(photoLibrary: photoLibrary)
                configuration.filter = PHPickerFilter.any(of: [.livePhotos, .videos, .images])
                configuration.preferredAssetRepresentationMode = .current
                configuration.selectionLimit = 9
                let picker = PHPickerViewController(configuration: configuration)
                picker.delegate = self
                self.present(picker, animated: true)
        }}
        
        @IBAction func album(_ sender: UIButton) {
                guard Wallet.shared.isStillVip() else {
                        showVipModalViewController()
                        return
                }
                
                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                if status == .denied || status == .restricted{
                        self.toastMessage(title: "authorize first please".locStr)
                        return
                }
                if status == .authorized{
                        accessPhoto()
                        return
                }
                
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { [unowned self] (status) in
                        if status == .denied {
                                self.toastMessage(title: "authorize failed".locStr)
                                return
                        }
                        accessPhoto()
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
        
        @IBAction func vipGuideBtn(_ sender: UIButton) {
                showVipModalViewController()
        }
}

extension MsgViewController{
        @IBAction func cancelRecord(_ sender: Any) {
                print("------>>>touch up outside")
        }
        
        func willCancelRecord() {
                self.recordingPoint.layer.contents = UIImage(named: "voicecancel_icon")?.cgImage
                self.recordingTip.text = "Release to cancel".locStr
        }
        
        func showCancelRecord() {
                self.recordingPoint.layer.contents = UIImage(named: "voiceBG_icon")?.cgImage
                self.recordingTip.text = "Slide to cancel".locStr
        }
        
        func beganRecord() {
                self.recordingPoint.isHidden = false
                self.recordingTip.isHidden = false
                self.recordBtn.setTitle("Release to send".locStr, for: .normal)
        }
        
        func endRecord() {
                self.recordingPoint.layer.contents = nil
                self.recordingTip.text = ""
                self.recordingPoint.isHidden = true
                self.recordingTip.isHidden = true
                self.recordBtn.setTitle("Press to record".locStr, for: .normal)
        }
        
        @IBAction func recordLongPress(_ sender: UILongPressGestureRecognizer) {
                
                if sender.state == .began {
                        if let err =  AudioRecordManager.shared.startRecord() {
                                self.toastMessage(title: err.localizedDescription)
                                return
                        }
                        recordCancelled = false
                        beganRecord()
                        
                } else if sender.state == .changed {
                        let point = sender.location(in: self.recordingPoint)
                        if self.recordingPoint.point(inside: point, with: nil) {
                                willCancelRecord()
                                recordCancelled = true
                        } else {
                                showCancelRecord()
                                recordCancelled = false
                        }
                } else if sender.state == .ended {
                        
                        AudioRecordManager.shared.finishRecrod(isReset: recordCancelled)
                        endRecord()
                        
                } else if sender.state == .cancelled {
                        AudioRecordManager.shared.finishRecrod(isReset: true)
                }
        }
        
        
        @IBAction func voiceBtn(_ sender: UIButton) {
                guard Wallet.shared.isStillVip() else{
                        showVipModalViewController()
                        return
                }
                
                if !isTextType {
                        self.voiceBtn.setImage(UIImage(named: "voice_icon"), for: .normal)
                        self.sender.isHidden = false
                        self.recordBtn.isHidden = true
                        isTextType = true
                        return
                }
                
                AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                        if !allowed {
                                self.toastMessage(title: "Need microphone right in setting".locStr)
                                return
                        }
                        DispatchQueue.main.async {
                                self.voiceBtn.setImage(UIImage(named: "key_icon"), for: .normal)
                                self.sender.isHidden = true
                                self.recordBtn.isHidden = false
                                self.isTextType = false
                        }
                }
        }
}

extension MsgViewController{
        
        @objc func contactUpdate(notification: NSNotification) {
                DispatchQueue.main.async {
                        self.setPeerBasic()
                        self.messageTableView.reloadData()
                }}
        
        @objc func peerNameUpdate(notification: NSNotification) {
                guard let pid = notification.object as? String, peerUid == pid else{
                        return
                }
                
                DispatchQueue.main.async {
                        self.setPeerBasic()
                }
        }
        @objc func currentGroupDismiessed(notification: NSNotification) {
                guard let pid = notification.object as? String,
                      peerUid == pid,  IS_GROUP else{
                              return
                      }
                DispatchQueue.main.async {
                        self.dismiss(animated: true)
                        self.navigationController?.popToRootViewController(animated: true)
                }
        }
        
        @objc func msgResult(notification: NSNotification){
                guard let msgID = notification.object as? Int64 else{
                        print("------>>> invalid msg resul notification")
                        return
                }
                guard msgID > 0 else{
                        self.toastMessage(title: "No rights to send message".locStr)
                        return
                }
                
                guard let idxPath = indexPathCache[msgID] else{
                        return
                }
                DispatchQueue.main.async {
                        self.messageTableView.reloadRows(at: [idxPath], with: .fade)
                }
        }
        
        @objc func newMsg(notification: NSNotification){
                guard let uid = notification.userInfo?[MessageItem.NotiKey] as? String else {
                        return
                }
                
                if uid != self.peerUid {
                        return
                }
                self.insertNewCell()
        }
        
        private func scrollToBottom(animated: Bool = false) {
                let rowCount = self.messageTableView.numberOfRows(inSection: 0)
                
                guard rowCount >= 2 else {
                        return
                }
                
                self.view.layoutIfNeeded()
                let bottomIndexPath = IndexPath.init(row: rowCount - 1, section: 0)
                self.messageTableView.scrollToRow(at: bottomIndexPath, at: .bottom, animated: animated)
        }
        
        private func insertNewCell(){
                DispatchQueue.main.async {
                        //                        let startCnt = self.messageTableView.numberOfRows(inSection: 0)
                        //                        let endCnt = self.msgCacheArray.count
                        //                        if startCnt >= endCnt{
                        //                                print("------>>> finish insert rows[\(endCnt)] in table")
                        //                                return
                        //                        }
                        //                        var indes :[IndexPath] = []
                        //                        for i in startCnt ... endCnt - 1{
                        //                                indes.append(IndexPath.init(row: i, section: 0))
                        //                        }
                        //                        //                        print("------>>> start rows[\(startCnt)] to end rows[\(endCnt)]")
                        //
                        //                        self.messageTableView.beginUpdates()
                        //                        self.messageTableView.insertRows(at: indes, with: .automatic)
                        //                        self.messageTableView.endUpdates()
                        //indes[indes.count - 1]
                        
                        self.msgCacheArray = MessageItem.SortedArray(pid: self.peerUid)
                        self.messageTableView.reloadData()
                        self.messageTableView.layoutIfNeeded()
                        self.messageTableView.scrollToRow(at: IndexPath.init(row: self.msgCacheArray.count - 1, section: 0),
                                                          at: .bottom, animated: true)
                }
        }
        
        func sendMessage(msg:MessageItem){
                let pid = msg.groupId ?? msg.to
                
                if let err = WebsocketSrv.shared.SendMessage(msg: msg){
                        msg.status = .faild
                        self.toastMessage(title: err.localizedDescription)
                        return
                }
                ServiceDelegate.workQueue.async {
                        if let e = MessageItem.processNewMessage(pid: pid, msg: msg, unread: 0){
                                self.toastMessage(title: e.localizedDescription)
                                return
                        }
                        self.insertNewCell()
                }
        }
}

extension MsgViewController{
        
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
        }
}
