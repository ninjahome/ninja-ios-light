//
//  MsgViewController+TextView.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/7.
//

import Foundation
import UIKit

extension MsgViewController: UITextViewDelegate {
        
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if (text == "\n") {
            guard let msg = self.sender.text, msg != "" else {
                    return false
            }
            
            let cliMsg = CliMessage.init()
            cliMsg.type = .plainTxt
            if IS_GROUP {
                cliMsg.groupId = self.peerUid
//                guard let group = groupData,
//                      let ids = group.memberIds as? [String] else {
//                    self.toastMessage(title: "Can not find group info")
//                    return false
//                }
                    cliMsg.to = self.peerUid
                cliMsg.textData = msg
                
            } else {
                cliMsg.to = peerUid
                cliMsg.textData = msg
            }
            
            textView.text = nil
            sendAllTypeMessage(cliMsg)

            return false
        }
        return true
    }
}
