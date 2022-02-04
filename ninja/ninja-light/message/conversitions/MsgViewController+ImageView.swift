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
                        self.toastMessage(title: "no valid image data")
                        return
                }
                
                var gid:String? = nil
                if IS_GROUP{
                        gid = self.peerUid
                }
                
                let msg = MessageItem.init(to: peerUid,
                                           data: imgMsg(data: data),
                                           typ: .image,
                                           gid: gid)
                
                sendMessage(msg: msg)
                
        }
        
        private func videoDidSelected(url: URL) {
                let name = url.lastPathComponent
                guard let data = try? Data(contentsOf: url), !data.isEmpty else{
                        self.toastMessage(title: "empty video file")
                        return
                }
                let maxSize = ChatLibMaxFileSize()
                let curSize = data.count
                if curSize < maxSize{
                        let thumb = VideoFileManager.thumbnailImageOfVideoInVideoURL(videoURL: url)
                        sendVideoFile(data: data, name: name, thumb: thumb)
                        return
                }
                
                self.showIndicator(withTitle: "", and: "compressing")
                ServiceDelegate.workQueue.async {
                        
                        VideoFileManager.compressVideo(from:curSize, to:maxSize, videoURL: url) {(status, resultUrl) in
                                
                                self.hideIndicator()
                                
                                switch status{
                                case .failed:
                                        self.toastMessage(title: "failed")
                                        break
                                case .cancelled:
                                        self.toastMessage(title: "cancelled")
                                        break
                                default:
                                        self.sendVideoFile(url: resultUrl)
                                }
                        }
                }
        }
        private func sendVideoFile(data:Data, name:String, thumb:UIImage?){
                var gid:String? = nil
                if IS_GROUP{
                        gid = self.peerUid
                }
                let video = videoMsg(name: name, data: data, thumb: thumb)
                let msg = MessageItem.init(to: peerUid,
                                           data: video,
                                           typ: .file,
                                           gid: gid)
                
                sendMessage(msg: msg)
        }
        
        private func sendVideoFile(url: URL){
                
                let name = url.lastPathComponent
                guard let data = try? Data(contentsOf: url), !data.isEmpty else{
                        self.toastMessage(title: "empty video file")
                        return
                }
                if data.count > ChatLibMaxFileSize(){
                        self.toastMessage(title: "file too big[\(data.count)]")
                        return
                }
                
                let thumb = VideoFileManager.thumbnailImageOfVideoInVideoURL(videoURL: url)
                
                sendVideoFile(data:data, name: name, thumb: thumb)
        }
}
