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
                for item in results{
                        let itemProvider = item.itemProvider
                        if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                                self.loadImage(provider:itemProvider)
                        }else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier){
                                self.loadVideo(provider:itemProvider)
                        }
                }
        }
        
        func loadImage(provider:NSItemProvider){
                provider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, err in
                        guard let url = url else{
                                self.toastMessage(title: "Invalid image data".locStr)
                                return
                        }
                        
                        do{
                                var data = try Data(contentsOf: url, options: .alwaysMapped)
                                let extenName = url.pathExtension
                                print("------>>>extenName=>", extenName)
                                
                                if !ChatLibIsValidImgFmt(url.pathExtension){
                                        guard let convertData  = UIImage(data: data)?.jpegData(compressionQuality: 1.0) else{
                                                self.toastMessage(title: "Invalid image data".locStr)
                                                return
                                        }
                                        data = convertData
                                }
                                
                                let has = ChatLibHashOfMsgData(data)
                                print("------>>>", has)
                                self.imageDidSelected(data: data)
                        }catch let err{
                                print("------>>>", err.localizedDescription)
                                self.toastMessage(title: err.localizedDescription)
                        }
                }
        }
        
        func loadVideo(provider:NSItemProvider){

                provider.loadInPlaceFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, inPlace, err in
                        guard let url = url else{
                                self.toastMessage(title: "Empty video file".locStr)
                                return
                        }
                        guard let data = try? Data.init(contentsOf: url) else{
                                self.toastMessage(title: "Empty video file".locStr)
                                return
                        }
                        self.videoDidSelected(data: data)
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
                        let (d, k, h) = ServiceDelegate.MakeImgSumMsg(origin: data, snapShotSize:maxSize)
                        guard let snapShot = d, let has = h, let key = k else{
                                self.hideIndicator()
                                self.toastMessage(title: "Invalid image data".locStr)
                                return
                        }
                        self.hideIndicator()
                        self.sendImgMsg(data:snapShot, has:has, key:key)
                }
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
        
        private func videoDidSelected(data:Data) {
                let has = ChatLibHashOfMsgData(data)
                print("------>>>data has :->", has)
                guard let url = VideoFileManager.writeByHash(has: has, content: data) else{
                        return
                }
                let maxSize = ChatLibMaxFileSize()
                let curSize = data.count
                if curSize < maxSize{
                        self.showIndicator(withTitle: "", and: "Compressing".locStr)
                        sendVideoFile(rawData: data, url:url)
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
                                        self.sendVideoFile(rawData: data, url:resultUrl)
                                }
                        }
                }
        }
        
        private func sendVideoFile(rawData:Data, url:URL){
                ServiceDelegate.workQueue.async {
                        let (thumb, isHorize) = VideoFileManager.thumbnailImageOfVideoInVideoURL(videoURL: url)
                        guard let thumbData = thumb else{
                                self.hideIndicator()
                                self.toastMessage(title: "create thumbnail failed".locStr)
                                return
                        }
                        let (hasOfVideo, key) = ServiceDelegate.MakeVideoSumMsg(rawData: rawData)
                        self.hideIndicator()
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
}
