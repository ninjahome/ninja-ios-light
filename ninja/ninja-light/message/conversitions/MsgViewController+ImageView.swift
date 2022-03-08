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
        
        private func pickImg(itemProvider:NSItemProvider, group:DispatchGroup){
                
                itemProvider.loadInPlaceFileRepresentation(forTypeIdentifier: ("public.image")) {url, inPlace, err in
                        
                        guard let url = url else{
                                group.leave()
                                self.toastMessage(title: "Invalid image data".locStr)
                                return
                        }
                        guard let data = try? Data(contentsOf: url), !data.isEmpty else{
                                itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, err in
                                        guard let d = data else{
                                                group.leave()
                                                self.toastMessage(title: "Invalid image data".locStr)
                                                return
                                        }
                                        self.imageDidSelected(imgData: d, group:group)
                                }
                                return
                        }
                        self.imageDidSelected(imgData: data, group:group)
                }
        }
        
        private func pickVideo(itemProvider:NSItemProvider, group:DispatchGroup){
                itemProvider.loadInPlaceFileRepresentation(forTypeIdentifier: "public.movie") { url, inPlace, err in
                        
                        guard let url = url else{
                                group.leave()
                                self.toastMessage(title: "Empty video file".locStr)
                                return
                        }
                        
                        guard let data = try? Data.init(contentsOf: url), !data.isEmpty else{
                                itemProvider.loadDataRepresentation(forTypeIdentifier: "public.movie") { data, err in
                                        guard let d = data, !d.isEmpty else{
                                                group.leave()
                                                self.toastMessage(title: "Empty video file".locStr)
                                                return
                                        }
                                        self.videoDidSelected(data: d, group: group)
                                }
                                return
                        }
                        
                        self.videoDidSelected(data: data, group: group)
                }
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                picker.dismiss(animated: true)
                guard !results.isEmpty else{
                        return
                }
                let itemProviders = results.map(\.itemProvider)
                self.showIndicator(withTitle: "", and: "Sending".locStr)
                
                ServiceDelegate.workQueue.async {
                        let group = DispatchGroup.init()
                        
                        for (_, itemProvider) in itemProviders.enumerated() {
                                group.enter()
                                if itemProvider.hasItemConformingToTypeIdentifier("public.image") {
                                        self.pickImg(itemProvider: itemProvider, group:group)
                                }else if itemProvider.hasItemConformingToTypeIdentifier("public.movie"){
                                        self.pickVideo(itemProvider: itemProvider, group:group)
                                }
                        }
                        _ = group.wait(timeout: .now() + 10)
                        self.hideIndicator()
                }
        }
}

extension MsgViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//                mutiMsgType.isHidden = true
                picker.dismiss(animated: true, completion: nil)
                if let mediaType = info[.mediaType] as? String {
                        switch mediaType {
                        case String(kUTTypeImage):
                                guard  let img = info[.originalImage] as? UIImage else {
                                        self.toastMessage(title: "Invalid image data".locStr)
                                        return
                                }
                                guard let imgData = img.rotateImage()?.jpegData(compressionQuality: 1.0) else{
                                        self.toastMessage(title: "Invalid image data".locStr)
                                        return
                                }
                                self.showIndicator(withTitle: "", and: "Sending".locStr)
                                ServiceDelegate.workQueue.async {
                                        let group = DispatchGroup.init()
                                        group.enter()
                                        self.imageDidSelected(imgData: imgData, group: group)
                                        _ = group.wait(timeout: .now() + 10)
                                        self.hideIndicator()
                                }
                        case String(kUTTypeVideo), String(kUTTypeMovie):
                                guard let url = info[.mediaURL] as? URL else{
                                        self.toastMessage(title: "Empty video file".locStr)
                                        return
                                }
                                guard let data = try? Data.init(contentsOf: url) else{
                                        self.toastMessage(title: "Empty video file".locStr)
                                        return
                                }
                                print("------>>>video data url :->", url.path)
                                self.showIndicator(withTitle: "", and: "Sending".locStr)
                                ServiceDelegate.workQueue.async {
                                        let group = DispatchGroup.init()
                                        group.enter()
                                        self.videoDidSelected(data: data, group: group)
                                        _ = group.wait(timeout: .now() + 10)
                                        self.hideIndicator()
                                }
                        default:
                                break
                        }
                }
        }
        
        
        private func imageDidSelected(imgData: Data, group:DispatchGroup) {
                defer{
                        group.leave()
                }
                
//                guard let data = UIImage(data: imgData)?.rotateImage()?.jpeg else{
//                        self.toastMessage(title: "Invalid image data".locStr)
//                        return
//                }
//
                let maxSize = ChatLibBigMsgThreshold()
                let curSize = imgData.count
                guard curSize > maxSize else{
                        sendImgMsg(data: imgData)
                        return
                }
                
                let (d, k, h) = ServiceDelegate.MakeImgSumMsg(origin: imgData, snapShotSize:maxSize)
                guard let snapShot = d, let has = h, let key = k else{
                        self.toastMessage(title: "Invalid image data".locStr)
                        return
                }
                self.sendImgMsg(data:snapShot, has:has, key:key)
        }
        
        private func sendImgMsg(data:Data, has:String = "", key:Data? = nil){
                var gid:String? = nil
                if IS_GROUP{
                        gid = self.peerUid
                }
                
                let msg = MessageItem.init(to: peerUid,
                                           data: imgMsg(data: data, has: has, key:key),
                                           typ: .image,
                                           gid: gid)
                
                sendMessage(msg: msg)
        }
        
        private func videoDidSelected(data:Data, group:DispatchGroup) {
                let has = ChatLibHashOfMsgData(data)
                print("------>>>video data has :->", has)
                guard let url = VideoFileManager.writeByHash(has: has, content: data) else{
                        group.leave()
                        return
                }
                let maxSize = ChatLibMaxFileSize()
                let curSize = data.count
                if curSize < maxSize{
                        sendVideoFile(rawData: data, url:url, group: group)
                        return
                }
                
                VideoFileManager.compressVideo(from:curSize, to:maxSize, videoURL: url) {(status, resultUrl) in
                        
                        switch status{
                        case .failed:
                                self.toastMessage(title: "Failed".locStr)
                                group.leave()
                                return
                        case .cancelled:
                                self.toastMessage(title: "Cancelled".locStr)
                                group.leave()
                                return
                        default:
                                guard let data = try? Data(contentsOf: resultUrl), !data.isEmpty else{
                                        group.leave()
                                        self.toastMessage(title: "Empty video file".locStr)
                                        return
                                }
                                self.sendVideoFile(rawData: data, url:resultUrl, group: group)
                        }
                }
        }
        
        private func sendVideoFile(rawData:Data, url:URL, group:DispatchGroup){
                
                defer{
                        group.leave()
                }
                
                let (thumb, isHorize) = VideoFileManager.thumbnailImageOfVideoInVideoURL(videoURL: url)
                guard let thumbData = thumb else{
                        self.toastMessage(title: "create thumbnail failed".locStr)
                        return
                }
                let (hasOfVideo, key) = ServiceDelegate.MakeVideoSumMsg(rawData: rawData)
                
                guard let has = hasOfVideo else{
                        self.toastMessage(title:  "Failed".locStr)
                        return
                }
                
                var gid:String? = nil
                if self.IS_GROUP{
                        gid = self.peerUid
                }
                let video = videoMsgWithHash(thumb:thumbData, has:has, isHorizon: isHorize, key: key)
                let msg = MessageItem.init(to: self.peerUid,
                                           data: video,
                                           typ: .videoWithHash,
                                           gid: gid)
                
                self.sendMessage(msg: msg)
        }
}
