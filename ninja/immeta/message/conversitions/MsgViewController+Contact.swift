//
//  MsgViewController+Contact.swift
//  immeta
//
//  Created by ribencong on 2022/3/2.
//

import Foundation

extension MsgViewController: SelectContactDelegate {
        func selectedIdStr(addr: String) {
                print("------>>>send contact msg: \(addr)")
                let owner = Wallet.shared.Addr!
                let payload = contactMsg.init(uid: addr, recommendor: owner)
                var gid:String? = nil
                if IS_GROUP{
                        gid = self.peerUid
                }
                let msg = MessageItem.init(to: self.peerUid, data: payload, typ: .contact, gid: gid)
                sendMessage(msg: msg)
        }
}
