//
//  MsgViewController+AudioView.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/7.
//

import Foundation
import UIKit

extension MsgViewController: RecordAudioDelegate {
        func audioRecordUpdateMetra(_ metra: Double) {
                print("-------->\(metra)")
                DispatchQueue.main.async {
                        self.recordSeconds.text = String.init(format: "%.1f", metra)
                }
        }
        
        func audioRecordTooShort() {
                self.toastMessage(title: "Record too short")
        }
        
        func audioRecordFailed() {
                self.toastMessage(title: "Record failed")
        }
        
        func audioRecordCanceled() {
                self.toastMessage(title: "Record canceled")
        }
        
        func audioRecordWavFinish(_ uploadWavData: Data, recordTime: Double, fileHash: String) {
                var gid:String? = nil
                if IS_GROUP{
                        gid = self.peerUid
                }
                
                let data = audioMsg.init(data: uploadWavData, len: Int(recordTime + 0.5))
                let msg = MessageItem.init(to: peerUid, data: data, typ: .voice, gid: gid)
                MessageItem.cache.setOrAdd(idStr: self.peerUid, item: self.msgCacheArray)
                MessageItem.syncNewIMToDisk(msg: msg)
                WebsocketSrv.shared.SendMessage(msg: msg)
        }
}

