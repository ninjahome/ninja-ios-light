//
//  MsgViewController+AudioView.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/7.
//

import Foundation
import UIKit

extension MsgViewController: RecordAudioDelegate {
        func audioRecordUpdateMetra(_ metra: Float) {
                print("\(metra)")
                DispatchQueue.main.async {
                        self.recordSeconds.text = String(Int(metra))
                }
                
        }
        
        func audioRecordTooShort() {
                self.toastMessage(title: "Record too short")
        }
        
        func audioRecordFailed() {
                self.toastMessage(title: "Record failed")
        }
        
        func audioRecordCanceled() {
                print("Record canceled")
        }
        
        func audioRecordFinish(_ uploadAmrData: Data, recordTime: Float, fileHash: String) {
                print("Record finished")
        }
        
        func audioRecordWavFinish(_ uploadWavData: Data, recordTime: Float, fileHash: String) {
                if recordTime < 1 {
                        self.toastMessage(title: "Record too short")
                        return
                }
                let cliMsg = CliMessage.init()
                cliMsg.type = .voice
                if IS_GROUP {
                        cliMsg.groupId = self.peerUid
                        //            guard let group = groupData,
                        //                  let ids = group.memberIds as? [String] else {
                        //                return
                        //            }
                        cliMsg.to = self.peerUid
                } else {
                        cliMsg.to = peerUid
                }
                let audio: audioMsg = audioMsg.init()
                audio.content = uploadWavData
                audio.duration = Int(recordTime)
                cliMsg.audioData = audio
                
                sendAllTypeMessage(cliMsg)
                
        }
        
}

