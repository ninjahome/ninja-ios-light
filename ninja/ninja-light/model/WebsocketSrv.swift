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
        
        func SendMessage(msg:MessageItem)->Error?{
                guard let data =  msg.payload?.wrappedToProto() else{
                        return NJError.msg("pack message failed")
                }
                
                var err: NSError? = nil
                guard let _ = ChatLibSend(msg.timeStamp, msg.to, data, msg.groupId != nil, &err), err != nil else{
                        return nil
                }
                return err
        }
}


extension WebsocketSrv: ChatLibUICallBackProtocol {
        func accountUpdate(_ p0: Data?) {
                guard let data = p0 else {
                        return
                }
                ServiceDelegate.SyncChainData(data: data)
        }
        
        func getMembersOfGroup(_ p0: String?) -> Data? {
                guard let gid = p0 else {
                        return nil
                }
                let data = GroupItem.getMembersOfGroup(gid: gid)
                return data
        }
        
        func groupUpdate(_ p0: Data?) {
        }
        
        func grpIM(_ from: String?, gid: String?, cryptKey: Data?, decoded: Data?, payload: Data?, time: Int64) throws {
                guard let f = from, let d = decoded, let grpId = gid  else{
                        print("------>>>[grpIM] invalid group message data")
                        return
                }
                
                WebsocketSrv.netQueue.async {
                        MessageItem.receiveMsg(from: f, gid: grpId, msgData: d, time: time)
                }
        }
        
        func msgResult(_ p0: Int64, p1: String?, p2: Bool) {
                guard let to = p1 else {
                        return
                }
                MessageItem.resetSending(msgid: p0, to: to, success: p2)
        }
        
        func nodeIPChanged(_ p0: String?) {
                guard let newIP = p0 else{
                        print("------->>>[nodeIPChanged] no valid ip address")
                        return
                }
                let conf = ConfigItem.initEndPoint(newIP)
                if let err = ConfigItem.updateConfig(conf) {
                        print("------->>>[nodeIPChanged] update config faild:\(String(describing: err.localizedDescription))")
                }
                WebsocketSrv.shared.Online()
        }
        
        func peerIM(_ from: String?, decoded: Data?, payload: Data?, time: Int64) throws {
                guard  let f = from, let d = decoded  else{
                        print("------>>>[peerIM] invalid peer message data")
                        return
                }
                WebsocketSrv.netQueue.async {
                        MessageItem.receiveMsg(from: f, gid: nil, msgData: d, time: time)
                }
        }
        
        func webSocketClosed() {
                NotificationCenter.default.post(name: NotifyWebsocketOffline,
                                                object: self,
                                                userInfo: nil)
        }
        
        func webSocketDidOnline() {
                print("------>>> socket online success")
                NotificationCenter.default.post(name: NotifyWebsocketOnline,
                                                object: self,
                                                userInfo: nil)
        }
}
