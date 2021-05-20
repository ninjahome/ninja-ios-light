//
//  WebsocketCallback.swift
//  ninja-light
//
//  Created by wesley on 2021/4/6.
//

import Foundation
import IosLib
import SwiftyJSON

class WebsocketSrv:NSObject{
        public static var shared = WebsocketSrv()
        override init() {
                super.init()
        }
        
        func IsOnline() -> Bool {
                
                return IosLib.IosLibWSIsOnline()
        }
        
        func Online()->Error?{
                var err:NSError? = nil
                IosLib.IosLibWSOnline(&err)
                return err
        }
        
        func Offline() {
                IosLib.IosLibWSOffline()
        }
        
        func SendIMMsg(cliMsg:CliMessage) -> NJError?{
                var error:NSError?
                var data:Data
                do{
                        data = try cliMsg.ToNinjaPayload()
                }catch let err{
                        return NJError.msg(err.localizedDescription)
                }
                
            print("cliMsg\(cliMsg)")
            print("cliMsg.to\(cliMsg.to)")
            print("\(JSON(data))")
                IosLib.IosLibWriteMessage(cliMsg.to, data, &error)
                if error != nil{
                        return NJError.msg(error!.localizedDescription)
                }
                
                let msg = MessageItem.addSentIM(cliMsg: cliMsg)
                ChatItem.updateLastMsg(peerUid: cliMsg.to!,
                                       msg: msg.coinvertToLastMsg(),
                                       time: Int64(Date().timeIntervalSince1970),
                                       unread: 0)
                return nil
        }
}

extension WebsocketSrv:IosLibAppCallBackProtocol{
        
        func immediateMessage(_ from: String?, to: String?, payload: Data?, time: Int64) throws {
                
                let owner = Wallet.shared.Addr!
                if owner != to {
                        throw NJError.msg("this im is not for me")
                }
                
                let cliMsg = try CliMessage.FromNinjaPayload(payload!, to: to!)
                let msg = MessageItem.init(cliMsg:cliMsg, from:from!, time:time, out:false)
                
                MessageItem.receivedIM(msg: msg)
                ChatItem.updateLastMsg(peerUid:from!,
                                       msg: msg.coinvertToLastMsg(),
                                       time: time,
                                       unread: 1)
        }
        
        func unreadMsg(_ jsonData: Data?) throws {
                guard let data = jsonData else {
                        return
                }
                
                var unreadItem:[String:ChatItem] = [:]
                let json = try JSON(data: data)
                var unreadMsg:[MessageItem] = []
                
                for (_,subJson):(String, JSON) in json{
                        let msg = MessageItem.init(json:subJson, out:false)
                        unreadMsg.append(msg)
                        let from = msg.from!
                        if unreadItem[from] == nil{
                                unreadItem[from] = ChatItem.init()
                                unreadItem[from]?.ItemID = from
                        }
                        
                        if  unreadItem[from]!.updateTime < msg.timeStamp{
                                unreadItem[from]?.updateTime = msg.timeStamp
                                unreadItem[from]?.LastMsg = msg.coinvertToLastMsg()
                                unreadItem[from]?.unreadNo += 1
                        }
                }
                
                try MessageItem.saveUnread(unreadMsg)
                try ChatItem.updateAllLastMsg(msg: unreadItem)
        }
        
        func webSocketClosed() {
                NotificationCenter.default.post(name:NotifyWebsocketOffline,
                                                object: self,
                                                userInfo:nil)
        }
}
