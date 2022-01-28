//
//  MsgViewController+FileView.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2022/1/27.
//

import Foundation
import UIKit

extension MsgViewController: UIDocumentPickerDelegate {
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                mutiMsgType.isHidden = true
                controller.dismiss(animated: true, completion: nil)
                guard let url = urls.first else {
                        return
                }
                
                documentFromURL(pickedURL: url)
        }
        
        private func documentFromURL(pickedURL: URL) {
                let name = pickedURL.lastPathComponent
                let dirURL = VideoFileManager.createVideoURL(name: name)
                if !FileManager.judgeFileOrFolderExists(filePath: dirURL.path) {
                        do {
                                try FileManager.copyFile(fileName: name, origin: pickedURL, to: dirURL)
                        } catch let err {
                                print("faild copy to sandbox\(err.localizedDescription)")
                        }
                }
                
                var cliMsg: CliMessage?
                if IS_GROUP {
                        cliMsg = CliMessage.init(to: peerUid, fileUrl: dirURL, groupId: peerUid)
                } else {
                        cliMsg = CliMessage.init(to: peerUid, fileUrl: dirURL, groupId: nil)
                }
                sendAllTypeMessage(cliMsg!)
        }
}
