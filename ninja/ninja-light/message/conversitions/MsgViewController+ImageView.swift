//
//  MsgViewController+ImageView.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/7.
//

import Foundation
import UIKit
import MobileCoreServices.UTType

extension MsgViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//                self.dismiss(animated: true, completion: nil)
//                picker.dismiss(animated: true, completion: nil)
//        }
        
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
                
                var cliMsg: CliMessage?
                if IS_GROUP {
                        cliMsg = CliMessage.init(to: peerUid, imgData: imagedata!, groupId: peerUid)
                } else {
                        cliMsg = CliMessage.init(to: peerUid, imgData: imagedata!, groupId: nil)
                }
                sendAllTypeMessage(cliMsg!)
                
        }
        
        private func videoDidSelected(url: URL) {
                let name = url.lastPathComponent
                let dirURL = VideoFileManager.createVideoURL(name: name)
                
                do {
                        try FileManager.copyFile(fileName: name, origin: url, to: dirURL)
                } catch let err {
                        print("faild copy to sandbox\(err.localizedDescription)")
                }
                
                var cliMsg: CliMessage?
                if IS_GROUP {
//                        guard let group = groupData, let ids = group.memberIds as? [String] else {
//                                return
//                        }
                        cliMsg = CliMessage.init(to: peerUid, videoUrl: dirURL, groupId: peerUid)
                } else {
                        cliMsg = CliMessage.init(to: peerUid, videoUrl: dirURL, groupId: nil)
                }
                sendAllTypeMessage(cliMsg!)
        }

}
