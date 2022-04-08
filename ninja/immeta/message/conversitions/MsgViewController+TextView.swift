//
//  MsgViewController+TextView.swift
//  immeta
//
//  Created by 郭晓芙 on 2021/12/7.
//

import Foundation
import UIKit

extension MsgViewController: UITextViewDelegate {
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
                guard text == "\n" else{
                        return true
                }
                
                guard let message = self.sender.text, message != "" else {
                        return false
                }
                var gid:String? = nil
                if IS_GROUP{
                        gid = self.peerUid
                }
                let data = txtMsg.init(txt: message)
                let msg = MessageItem.init(to: peerUid, data: data, typ: .plainTxt, gid: gid)
                msg.isOut = true
                textView.text = nil
                sendMessage(msg: msg)
                return false
        }
}
