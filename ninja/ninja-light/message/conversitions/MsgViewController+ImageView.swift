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
                let itemProviders = results.map(\.itemProvider)
                for (_, itemProvider) in itemProviders.enumerated() {
                        if itemProvider.hasItemConformingToTypeIdentifier("public.image") {
                                self.loadImage(provider:itemProvider)
                        }else if itemProvider.hasItemConformingToTypeIdentifier("public.movie"){
                                self.loadMovie(provider:itemProvider)
                        }
                }
        }
        
        func loadImage(provider:NSItemProvider){
                provider.loadInPlaceFileRepresentation(forTypeIdentifier: "public.image") { url, inPlace, err in
                        guard let url = url else{
                                self.loadImage2(provider: provider)
                                print("------>>> loadImage err:=>", err?.localizedDescription ?? "<->")
                                return
                        }
                        guard let data = try? Data(contentsOf: url), !data.isEmpty else{
                                self.loadImage2(provider: provider)
                                print("------>>>loadImage data is nil:=>")
                                return
                        }
                        self.imageDidSelected(imgData: data, extenName: url.pathExtension)
                        print("------>>>loadImage step1 ulock")
                }
        }
        
        func loadImage2(provider:NSItemProvider){
                provider.loadDataRepresentation(forTypeIdentifier: "public.image") { data, err in
                        guard let data = data else{
                                self.toastMessage(title: "Invalid image data".locStr)
                                print("------>>>err:=>", err?.localizedDescription ?? "<->")
                                print("------>>>loadImage2 step1 ulock")
                                return
                        }
                        guard let convertData  = UIImage(data: data)?.jpegData(compressionQuality: 1.0) else{
                                self.toastMessage(title: "Invalid image data".locStr)
                                print("------>>>loadImage2 step1 ulock")
                                return
                        }
                        self.imageDidSelected(imgData: convertData, extenName: "jpeg")
                        print("------>>>loadImage2 step1 ulock")
                }
        }
        
        func loadMovie(provider:NSItemProvider){
                
                provider.loadInPlaceFileRepresentation(forTypeIdentifier: "public.movie") { url, inPlace, err in
                         
                        guard let url = url else{
                                self.loadMovie2(provider: provider)
                                return
                        }
                        guard let data = try? Data.init(contentsOf: url), !data.isEmpty  else{
                                print("------>>>first vedio load failed url:",url.path, err?.localizedDescription ?? "<->")
                                self.loadMovie2(provider: provider)
                                return
                        }
                        
                        self.videoDidSelected(data: data)
                }
        }
        
        func loadMovie2(provider:NSItemProvider){
                provider.loadFileRepresentation(forTypeIdentifier: "public.movie") { url, err in
                        guard let url = url else{
                                self.toastMessage(title: "Empty video file".locStr, duration: 1.0)
                                print("------>>>Empty video file url is nil", err?.localizedDescription ?? "<->")
                                return
                        }
                        guard let data = try? Data.init(contentsOf: url),data.isEmpty else{
                                self.hideIndicator()
                                self.toastMessage(title: "Empty video file".locStr, duration: 1.0)
                                print("------>>>Empty video file url:",url.path)
                                return
                        }
                        self.videoDidSelected(data: data)
                }
        }
}

extension MsgViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        
        private func imageDidSelected(imgData: Data, extenName:String) {
                
                print("------>>>extenName=>", extenName)
                var data = imgData
                if !ChatLibIsValidImgFmt(extenName){
                        guard let convertData  = UIImage(data: data)?.jpegData(compressionQuality: 1.0) else{
                                self.toastMessage(title: "Invalid image data".locStr)
                                return
                        }
                        data = convertData
                }
                
                print("------>>> image hash:=>", ChatLibHashOfMsgData(data))
                let maxSize = ChatLibBigMsgThreshold()
                let curSize = data.count
                guard curSize > maxSize else{
                        sendImgMsg(data: data)
                        return
                }
                
                let (d, k, h) = ServiceDelegate.MakeImgSumMsg(origin: data, snapShotSize:maxSize)
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
        
        private func videoDidSelected(data:Data) {
                let has = ChatLibHashOfMsgData(data)
                print("------>>>data has :->", has)
                guard let url = VideoFileManager.writeByHash(has: has, content: data) else{
                        return
                }
                let maxSize = ChatLibMaxFileSize()
                let curSize = data.count
                if curSize < maxSize{
                        sendVideoFile(rawData: data, url:url)
                        return
                }
                VideoFileManager.compressVideo(from:curSize, to:maxSize, videoURL: url) {(status, resultUrl) in
                        
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
        
        private func sendVideoFile(rawData:Data, url:URL){
                
                ServiceDelegate.workQueue.async {
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
}
