//
//  WebsocketCallback.swift
//  ninja-light
//
//  Created by wesley on 2021/4/6.
//

import Foundation
//import SwiftyJSON
import ChatLib
import UIKit

class WebsocketSrv: NSObject {
        public static var shared = WebsocketSrv()

        public static let netQueue = DispatchQueue.init(label: "Connect Queue", qos: .userInteractive)

        public static let textMsgQueue = DispatchQueue.init(label: "Sending Text Queue")
        public static let imageMsgQueue = DispatchQueue.init(label: "Sending Image Queue")
        public static let voiceMsgQueue = DispatchQueue.init(label: "Sending Voice Queue")
        public static let locationMsgQueue = DispatchQueue.init(label: "Sending Location Queue")

        override init() {
                super.init()
        }
    
    
        func Online() {
                WebsocketSrv.netQueue.async {
                        var err: NSError? = nil
                        ChatLibWSOnline(&err)
                        if err != nil {
                                print("online err \(String(describing: err?.localizedDescription))")
                                NotificationCenter.default.post(name: NotifyOnlineError,
                                                                object: self,
                                                                userInfo: nil)
                        }
                }
        }
    
        func Offline() {
                ChatLibWSOffline()
        }
    
        func SendIMMsg(cliMsg: CliMessage, retry: Bool = false, onStart: @escaping()-> Void, onCompletion: @escaping(Bool) -> Void) {
        
                var isGroup: Bool = false
                var peerID:String
                if let groupId = cliMsg.groupId {
                        isGroup = true
                        peerID = groupId
                } else {
                        peerID = cliMsg.to!
                }
                
                if retry {
                        onStart()
                } else {
                        let msg = MessageItem.addSentIM(cliMsg: cliMsg)
                        onStart()
                        ChatItem.updateLastMsg(peerUid: peerID,
                                               msg: msg.coinvertToLastMsg(),
                                               time: msg.timeStamp,
                                               unread: 0,
                                               isGroup: isGroup)
                }
        
            
                guard let data =  cliMsg.PackData() else{
                        return
                }
                
                var err: NSError? = nil
                ChatLibSend(cliMsg.timestamp ?? Int64(Date().timeIntervalSince1970), cliMsg.to, data, isGroup, &err)
                if err != nil {
                        onCompletion(false)
                        print("send msg error\(String(describing: err?.localizedDescription))")
                }
                
                onCompletion(true)
                
        }
}


extension WebsocketSrv: ChatLibUICallBackProtocol {
        func accountUpdate(_ p0: Data?) {
                guard let data = p0,
                        let wallet = Wallet.initByData(data) else {
                        return
                }
                guard let err = Wallet.shared.UpdateWallet(w: wallet) else {
                        //TODO:: update contact and group
                        
                        return
                }
                print(String(err.localizedDescription))
        }
        
        func getMembersOfGroup(_ p0: String?) -> Data? {
                return nil
        }
        
        func groupUpdate(_ p0: Data?) {
                if let data = p0,
                   let grpItem = GroupItem.initByData(data) {
                        if let err = GroupItem.UpdateGroup(grpItem) {
                                print("update grp faild:\(String(describing: err.localizedDescription))")
                        }
                }
        }
        
        func grpIM(_ from: String?, gid: String?, cryptKey: Data?, decoded: Data?, payload: Data?, time: Int64) throws {
                if let f = from, let d = decoded {
                        MessageItem.receiveMsg(from: f, gid: gid, msgData: d, time: time)
                }
        }
        
        func msgResult(_ p0: Int64, p1: String?, p2: Bool) {
                guard let to = p1 else {
                        return
                }
                MessageItem.resetSending(msgid: p0, to: to, success: p2)
        }
        
        func nodeIPChanged(_ p0: String?) {
                if let str = p0 {
                        let conf = ConfigItem.initEndPoint(str)
                        if let err = ConfigItem.updateEndPoint(conf) {
                                print("update config faild:\(String(describing: err.localizedDescription))")
                        }
                }
        }
        
        func peerIM(_ from: String?, decoded: Data?, payload: Data?, time: Int64) throws {
                if let f = from, let d = decoded {
                        MessageItem.receiveMsg(from: f, gid: nil, msgData: d, time: time)
                }
        }
        
        func webSocketClosed() {
                NotificationCenter.default.post(name: NotifyWebsocketOffline,
                                                                object: self,
                                                                userInfo: nil)
        }
        
        func webSocketDidOnline() {
                NotificationCenter.default.post(name: NotifyWebsocketOnline,
                                                                object: self,
                                                                userInfo: nil)
        }
        
        
}
