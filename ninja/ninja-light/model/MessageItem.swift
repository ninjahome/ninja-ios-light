//
//  MessageItem.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import CoreData
import SwiftyJSON
import ChatLib

typealias MessageList = [MessageItem]

class MessageItem: NSObject {
        
        public static let NotiKey = "peerUid"
        var timeStamp:Int64 = 0
        var from:String?
        var to:String?
        var typ:CMT = .plainTxt
        var payload:Any?
        var isOut:Bool = false
        
        public static var cache:[String:MessageList] = [:]
        override init() {
                super.init()
        }
        
        public static func loadUnread(){
                guard let owner = Wallet.shared.Addr else {
                    return
                }
                var result:[MessageItem]?
                result = try? CDManager.shared.Get(entity: "CDUnread",
                                                   predicate: NSPredicate(format: "owner == %@", owner))
                guard let data = result else{
                        return
                }
                cache.removeAll()
                for msg in data{
                        
                        var peerUid:String
                        if msg.isOut{
                                peerUid = msg.to!
                        }else{
                                peerUid = msg.from!
                        }
                        
                        if cache[peerUid] == nil{
                                cache[peerUid] = MessageList.init()
                        }
                        
                        cache[peerUid]?.append(msg)
                }
            
        }
        
        public static func removeRead(_ uid:String){
                cache.removeValue(forKey: uid)
                let owner = Wallet.shared.Addr!
                try? CDManager.shared.Delete(entity: "CDUnread",
                                        predicate: NSPredicate(format: "owner == %@ AND (from == %@ OR to == %@)",
                                                               owner, uid, uid))
        }
    
        public static func removeAllRead() {
            cache.removeAll()
            let owner = Wallet.shared.Addr!
            try? CDManager.shared.Delete(entity: "CDUnread",
                                    predicate: NSPredicate(format: "owner == %@", owner))
            
        }
        
        func coinvertToLastMsg() -> String{
            switch self.typ {
                case .plainTxt:
//                        let time = Date.init(timeIntervalSince1970: TimeInterval(self.timeStamp))
//                    dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    
//                        return dateFormatterGet.string(from: time)
                    return "[Text Message]"
                case .voice:
                        return "[Voice Message]"
                case .video:
                        return "[Video Message]"
                case .location:
                        return "[Location]"
                case .contact:
                        return "[Contact]"
                case .image:
                        return "[Image]"
            }
        }
        
//        init(json:JSON, out:Bool){
//
//                self.from = json["From"].string
//                self.to = json["To"].string
//                self.timeStamp = json["UnixTime"].int64 ?? 0
//                self.isOut = out
//
//                let payStr = json["PayLoad"].string
//                if let data = IosLib.IosLibUnmarshalGoByte(payStr){
//                        let cliMsg = try? CliMessage.FromNinjaPayload(data, to: self.to!)
//                        self.typ = cliMsg!.type
//
//                        switch self.typ {
//                        case .plainTxt:
//                            self.payload = cliMsg?.textData
//                        case .image:
//
//                            self.payload = cliMsg?.imgData
//                        case .voice:
//                            self.payload = cliMsg?.audioData
//                        default:
//                            print("init MESSAGE error: undefined type")
//                        }
//                }
//        }
        
        init(cliMsg:CliMessage, from: String, time: Int64, out:Bool) {
                super.init()
                self.from = from
                self.timeStamp = time
                self.to = cliMsg.to
                self.typ = cliMsg.type
            
                switch self.typ {
                case .plainTxt:
                    self.payload = cliMsg.textData
                case .image:
                    self.payload = cliMsg.imgData
                case .voice:
                    self.payload = cliMsg.audioData
                case .location:
                    self.payload = cliMsg.locationData
//                    if let ad = cliMsg.audioData {
//                        if let url = AudioFilesManager.saveWavData(ad, fileName: String(time)) {
//                            self.payload = url.path
//                        }
//                    }
                default:
                    print("init MESSAGE error: undefined type")
                }

                self.isOut = out
        }
        
        public static func addSentIM(cliMsg:CliMessage) -> MessageItem {
                
                let sender = Wallet.shared.Addr!
                let msg = MessageItem.init()
                msg.from = sender
                msg.to = cliMsg.to
                msg.typ = cliMsg.type
                msg.timeStamp = Int64(Date().timeIntervalSince1970)
                msg.isOut = true
//                msg.payload = cliMsg.data
                switch msg.typ {
                case .plainTxt:
                    msg.payload = cliMsg.textData
                case .image:
                    msg.payload = cliMsg.imgData
                case .voice:
                    msg.payload = cliMsg.audioData
                case .location:
                    msg.payload = cliMsg.locationData
//                    if let ad = cliMsg.audioData {
//                        if let url = AudioFilesManager.saveWavData(ad, fileName: String(msg.timeStamp)) {
//                            msg.payload = url.path
//                        }
//                    }
//                    msg.payload = cliMsg.audioData
                default:
                    print("init MESSAGE error: undefined type")
                }
                
                if cache[msg.to!] == nil{
                        cache[msg.to!] = []
                }
                cache[msg.to!]!.append(msg)
                
                try? CDManager.shared.AddEntity(entity: "CDUnread", m: msg)
                return msg
        }
        
        public static func receivedIM(msg:MessageItem){
                if cache[msg.from!] == nil{
                        cache[msg.from!] = []
                }
                cache[msg.from!]!.append(msg)
                cache[msg.from!]!.sort(by: { (a, b) -> Bool in
                        return a.timeStamp < b.timeStamp
                })
                try? CDManager.shared.AddEntity(entity: "CDUnread", m: msg)
                NotificationCenter.default.post(name:NotifyMessageAdded,
                                                object: self, userInfo:[NotiKey:msg.from!])
        }
        
        public static func saveUnread(_ msg:[MessageItem])throws {
                try CDManager.shared.AddBatch(entity: "CDUnread", m: msg)
                loadUnread()
        }
}

extension MessageItem: ModelObj {
        
        func fullFillObj(obj: NSManagedObject) throws {
                guard let uObj = obj as? CDUnread else {
                        throw NJError.coreData("cast to unread item obj failed")
                }
                let owner = Wallet.shared.Addr!
                uObj.type = Int16(self.typ.rawValue)
                uObj.from = self.from
                uObj.isOut = self.isOut
                
                switch self.typ {
                case .plainTxt:
                    uObj.message = self.payload as? String
                case .image:
                    uObj.image = self.payload as? Data
                case .voice:
                    uObj.media = self.payload as? NSObject
                case .location:
                    uObj.media = self.payload as? NSObject
                default:
                    print("full fill msg: no such type")
                }
//                uObj.message = self.payload as? String
                uObj.owner = owner
                uObj.to = self.to
                uObj.unixTime = self.timeStamp
            
        }
        
        func initByObj(obj: NSManagedObject) throws {
                guard let uObj = obj as? CDUnread else {
                        throw NJError.coreData("cast to unread item obj failed")
                }
                self.typ = CMT(rawValue: Int(uObj.type))!
            
                self.from = uObj.from
                self.isOut = uObj.isOut
            
                switch self.typ {
                case .plainTxt:
                    self.payload = uObj.message
                case .image:
                    self.payload = uObj.image
                case .voice:
                    self.payload = uObj.media as? audioMsg
                case .location:
                    self.payload = uObj.media as? locationMsg
                default:
                    print("init by msg obj: no such type")
                }
            
//                self.payload = uObj.message
                self.to = uObj.to
                self.timeStamp = uObj.unixTime
        }
}

extension MessageList {
        
        func toString() -> String {
                
                var str = ""
                for msg in self{
                        switch msg.typ {
                        case .plainTxt:
                                if msg.isOut{
                                        str += "[me]:"
                                }
                                str += "\(msg.payload!)\r\n"
                        case .contact://TODO::
                                str += "Contact TODO::\r\n"
                        case .voice://TODO::
                                str += "Voice TODO::\r\n"
                        case .location://TODO::
                                str += "Location TODO::\r\n"
                        case .image:
                                str += "Image TODO::\r\n"
                        case .video:
                            str += "Video TODO::\r\n"
                        }
                }
                return str
        }
}
