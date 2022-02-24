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
import PhotosUI

extension MsgViewController:PHPickerViewControllerDelegate{
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                picker.dismiss(animated: true)
                guard !results.isEmpty else{
                        return
                }
                let itemProvider = results[0].itemProvider
                if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        self.loadImage(provider:itemProvider)
                }
        }
        
        func loadImage(provider:NSItemProvider){
                provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                        guard let data = data else{
                                return
                        }
                        
                        self.imageDidSelected(data: data)
                }
        }
}

extension MsgViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        

        private func imageDidSelected(data: Data) {
                
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
                let has = ChatLibHashOfMsgData(data)
                print("------>>>ahs=>", has, url.path)
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
                        let hasOfVideo = ServiceDelegate.MakeVideoSumMsg(rawData: rawData)
                        self.hideIndicator()
                        guard let has = hasOfVideo else{
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
