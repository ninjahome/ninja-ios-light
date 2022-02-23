//
//  MsgViewController+ImageView.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/7.
//

import Foundation
import UIKit
import MobileCoreServices.UTType
import ChatLib

extension MsgViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                mutiMsgType.isHidden = true
                picker.dismiss(animated: true, completion: nil)
                if let mediaType = info[.mediaType] as? String {
                        switch mediaType {
                        case String(kUTTypeImage):
                                
                                if let img = info[.originalImage] as? UIImage {
                                        imageDidSelected(img: img)
                                }
                        case String(kUTTypeVideo), String(kUTTypeMovie):
                                if let url = info[.mediaURL] as? URL {
                                        videoDidSelected(url: url)
                                }
                        default:
                                break
                        }
                }
        }
        
        private func imageDidSelected(img: UIImage) {
                var imagedata: Data?
                if img.jpeg != nil {
                        imagedata = img.jpeg
                } else {
                        imagedata = img.png
                }
                
                guard let data = imagedata else{
                        self.toastMessage(title: "Invalid image data".locStr)
                        return
                }
                
                let maxSize = ChatLibBigMsgThreshold()
                let curSize = data.count
                guard curSize > maxSize else{
                        sendImgMsg(data: data)
                        return
                }
                
                self.showIndicator(withTitle: "", and: "压缩......")
                ServiceDelegate.workQueue.async {
                        let (d, h) = ServiceDelegate.MakeImgSumMsg(origin: data, snapShotSize:maxSize)
                        guard let snapShot = d, let has = h else{
                                self.hideIndicator()
                                self.toastMessage(title: "Invalid image data".locStr)
                                return
                        }
                        self.hideIndicator()
                        self.sendImgMsg(data:snapShot, has:has)
                }
        }
        
        private func sendImgMsg(data:Data,has:String = ""){
                var gid:String? = nil
                if IS_GROUP{
                        gid = self.peerUid
                }
                
                let msg = MessageItem.init(to: peerUid,
                                           data: imgMsg(data: data, has: has),
                                           typ: .image,
                                           gid: gid)
                
                sendMessage(msg: msg)
        }
        
        private func videoDidSelected(url: URL) {
                
                guard let data = try? Data(contentsOf: url), !data.isEmpty else{
                        self.toastMessage(title: "Empty video file".locStr)
                        return
                }
                let (thumb, isHorize) = VideoFileManager.thumbnailImageOfVideoInVideoURL(videoURL: url)
                guard let thumbData = thumb?.jpeg else{
                        self.toastMessage(title: "create thumbnail failed".locStr)
                        return
                }
                
                let maxSize = ChatLibMaxFileSize()
                let curSize = data.count
                if curSize < maxSize{
                        sendVideoFile(thumbData: thumbData, rawData: data, isHorize:isHorize)
                        return
                }
                
                self.showIndicator(withTitle: "", and: "Compressing".locStr)
                ServiceDelegate.workQueue.async {
                        VideoFileManager.compressVideo(from:curSize, to:maxSize, videoURL: url) {(status, resultUrl) in
                                self.hideIndicator()
                                
                                switch status{
                                case .failed:
                                        self.toastMessage(title: "Failed".locStr)
                                        break
                                case .cancelled:
                                        self.toastMessage(title: "Cancelled".locStr)
                                        break
                                default:
                                        guard let data = try? Data(contentsOf: resultUrl), !data.isEmpty else{
                                                self.toastMessage(title: "Empty video file".locStr)
                                                return
                                        }
                                        self.sendVideoFile(thumbData: thumbData, rawData: data, isHorize:isHorize)
                                }
                        }
                }
        }
        
        private func sendVideoFile(thumbData:Data, rawData:Data, isHorize:Bool){
                self.showIndicator(withTitle: "", and: "Compressing".locStr)
                
                ServiceDelegate.workQueue.async {
                        guard let has = ServiceDelegate.MakeVideoSumMsg(rawData: rawData) else{
                                self.hideIndicator()
                                self.toastMessage(title:  "Failed".locStr)
                                return
                        }
                        
                        var gid:String? = nil
                        if self.IS_GROUP{
                                gid = self.peerUid
                        }
                        let video = videoMsgWithHash(thumb:thumbData, has:has, isHorizon: isHorize)
                        let msg = MessageItem.init(to: self.peerUid,
                                                   data: video,
                                                   typ: .file,
                                                   gid: gid)
                        
                        self.sendMessage(msg: msg)
                }
        }
}
