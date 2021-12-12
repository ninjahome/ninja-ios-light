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
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
                picker.dismiss(animated: true, completion: nil)
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
                mutiMsgType.isHidden = true
                if let mediaType = info[.mediaType] as? String {
                        switch mediaType {
                        case String(kUTTypeImage):
                                
                                if let img = info[.originalImage] as? UIImage {
                                        imageDidSelected(img: img)
                                }
                        case String(kUTTypeVideo):
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
                        guard let group = groupData, let ids = group.memberIds as? [String] else {
                                return
                        }
                        cliMsg = CliMessage.init(to: ids.toString()!, imgData: imagedata!, groupId: peerUid)
                } else {
                        cliMsg = CliMessage.init(to: peerUid, imgData: imagedata!, groupId: nil)
                }
                sendAllTypeMessage(cliMsg!)
                
        }
        
        private func videoDidSelected(url: URL) {
                let fileManager = FileManager.default
                let data = fileManager.contents(atPath: url.path) ?? Data()
                
                var cliMsg: CliMessage?
                if IS_GROUP {
                        guard let group = groupData, let ids = group.memberIds as? [String] else {
                                return
                        }
                        cliMsg = CliMessage.init(to: ids.toString()!, videoData: data, videoUrl: url, groupId: peerUid)
                } else {
                        cliMsg = CliMessage.init(to: peerUid, videoData: data, videoUrl: url, groupId: nil)
                }
                sendAllTypeMessage(cliMsg!)
        }

}
