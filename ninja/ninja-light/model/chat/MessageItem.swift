//
//  MessageItem.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import CoreData
import ChatLib
import SwiftyJSON

typealias MessageList = [MessageItem]

enum sendingStatus: Int16 {
        case sent = 0
        case sending
        case faild
}

class MessageItem: NSObject {
        public static let NotiKey = "peerUid"
        var timeStamp: Int64 = 0
        var from: String?
        var to: String?
        var typ: CMT = .plainTxt
        var payload: Any?
        var isOut: Bool = false
        var groupId: String?
        var status: sendingStatus = .sent
        var avatarInfo: Avatar?

        public static var cache = LockCache<MessageList>()

        override init() {
                super.init()
        }
        
        public static func initByData(_ data: Data, from: String, gid: String? = nil, time: Int64) -> MessageItem? {
                guard let typ: CMT = CMT(rawValue: Int(data[0])),
                      let objJson = try? JSON(data: data[1...]) else {
                        return nil
                }
                let msgItem = MessageItem()
                msgItem.typ = typ
                msgItem.from = from
                msgItem.timeStamp = time
                msgItem.groupId = gid
                switch typ {
                case .plainTxt:
                        msgItem.payload = objJson.string
                case .image:
                        msgItem.payload = objJson.rawValue as? Data
                case .voice:
                        let audiomsg = audioMsg()
                        audiomsg.content = objJson["content"].rawValue as! Data
                        audiomsg.duration = objJson["len"].int!
                        
                        msgItem.payload = audiomsg
                case .location:
                        let locMsg = locationMsg()
                        locMsg.str = objJson["name"].string!
                        locMsg.la = objJson["lat"].floatValue
                        locMsg.lo = objJson["long"].floatValue
                        
                        msgItem.payload = locMsg
                case .video:
                        return nil
                case .contact:
                        return nil
                case .file:
                        return nil
                }
                return msgItem
        }

        public static func loadUnread() {
                guard let owner = Wallet.shared.Addr else {
                        return
                }
                var result:[MessageItem]?
                result = try? CDManager.shared.Get(entity: "CDUnread",
                                   predicate: NSPredicate(format: "owner == %@", owner))
                guard let data = result else{
                        return
                }
                cache.deleteAll()

                for msg in data {
                        var peerUid: String
                        if let groupId = msg.groupId {
                                peerUid = groupId
                        } else {
                                if msg.isOut {
                                        peerUid = msg.to!
                                } else {
                                        peerUid = msg.from!
                                }
                        }

                        var msgList = cache.get(idStr: peerUid)
                        if msgList == nil {
                                msgList = MessageList.init()
                        }
                        msgList!.append(msg)

                        cache.setOrAdd(idStr: peerUid, item: msgList)
                }
        }
        
        public static func getItemByTime(mid: Int64, to: String) -> MessageItem? {
                let owner = Wallet.shared.Addr!
                var result: MessageItem?
                do {
                        result = try CDManager.shared.GetOne(entity: "CDUnread",
                                                             predicate: NSPredicate(format: "owner == %@ AND to == %@ AND unixTime == %@", owner, to, mid))
                } catch let err {
                        print(err.localizedDescription)
                }
                return result
        }
    
        public static func removeRead(_ uid: String){
                cache.delete(idStr: uid)
                let owner = Wallet.shared.Addr!
                try? CDManager.shared.Delete(entity: "CDUnread",
                        predicate: NSPredicate(format: "owner == %@ AND (from == %@ OR to == %@)",
                                               owner, uid, uid))
        }

        public static func removeAllRead() {
                cache.deleteAll()
                let owner = Wallet.shared.Addr!
                try? CDManager.shared.Delete(entity: "CDUnread",
                        predicate: NSPredicate(format: "owner == %@", owner))
        }

        func coinvertToLastMsg() -> String{
                switch self.typ {
                case .plainTxt:
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
                case .file:
                        return "[File]"
                }
        }
        
        init(cliMsg: CliMessage, from: String, time: Int64, out:Bool) {
                super.init()
                self.from = from
                self.timeStamp = time
                self.to = cliMsg.to
                self.typ = cliMsg.type
                self.groupId = cliMsg.groupId

                switch self.typ {
                case .plainTxt:
                        self.payload = cliMsg.textData
                case .image:
                        self.payload = cliMsg.imgData
                case .voice:
                        self.payload = cliMsg.audioData
                case .location:
                        self.payload = cliMsg.locationData
                case .file:
                        self.payload = cliMsg.fileData
                case .video:
                        self.payload = cliMsg.videoData
                default:
                        print("init MESSAGE error: undefined type")
                }

                self.isOut = out
        }
    
        init(cliMsg: CliMessage) {
                let sender = Wallet.shared.Addr!
                self.from = sender

                if let groupid = cliMsg.groupId {
                        self.to = groupid
                } else {
                        self.to = cliMsg.to
                }

                self.typ = cliMsg.type
                self.timeStamp = cliMsg.timestamp ?? Int64(Date().timeIntervalSince1970)
                self.isOut = true
                self.groupId = cliMsg.groupId

                switch self.typ {
                case .plainTxt:
                        self.payload = cliMsg.textData
                case .image:
                        self.payload = cliMsg.imgData
                case .voice:
                        self.payload = cliMsg.audioData
                case .location:
                        self.payload = cliMsg.locationData
                case .video:
                        self.payload = cliMsg.videoData
                case .file:
                        self.payload = cliMsg.fileData
                default:
                        print("init MESSAGE error: undefined type")
                }
                self.status = .sending
        }
    
        public static func addSentIM(cliMsg: CliMessage) -> MessageItem {
                let msg = MessageItem.init(cliMsg: cliMsg)

                var msgList = cache.get(idStr: msg.to!)
                if msgList == nil {
                        msgList = []
                }
                msgList?.append(msg)
                cache.setOrAdd(idStr: msg.to!, item: msgList)

                try? CDManager.shared.AddEntity(entity: "CDUnread", m: msg)
                return msg
        }
        
        public static func resetSending(msgid: Int64, to: String, success: Bool) {
                guard let msg = MessageItem.getItemByTime(mid: msgid, to: to) else {
                        return
                }
                let owner = Wallet.shared.Addr!
                if success {
                        msg.status = .sent
                } else {
                        msg.status = .faild
                }

                var peerUid: String?
                if let gid = msg.groupId {
                        peerUid = gid
                } else {
                        peerUid = msg.to
                }

                if var msgs = MessageItem.cache.get(idStr: peerUid!) {
                        for (index, item) in msgs.enumerated() {
                                if item.timeStamp == msg.timeStamp {
                                        msgs[index] = msg
                                        break
                                }
                        }
                        MessageItem.cache.setOrAdd(idStr: peerUid!, item: msgs)
                        try? CDManager.shared.UpdateOrAddOne(entity: "CDUnread", m: msg,
                                                         predicate: NSPredicate(format: "owner == %@ AND unixTime == %@",
                                                                                owner, NSNumber(value: msg.timeStamp)))


                        for item in msgs {
                                print(item.status)
                                print(item.typ)
                        }
                }

        }
    
        public static func receivedIM(msg: MessageItem) {
                var peerUid: String

                if let groupId = msg.groupId {
                        peerUid = groupId
                } else {
                        peerUid = msg.from!
                }

                var msgList = cache.get(idStr: peerUid)
                if msgList == nil {
                        msgList = []
                }

                msgList?.append(msg)
                msgList?.sort(by: { (a, b) -> Bool in
                        return a.timeStamp < b.timeStamp
                })
                cache.setOrAdd(idStr: peerUid, item: msgList)

                try? CDManager.shared.AddEntity(entity: "CDUnread", m: msg)
                NotificationCenter.default.post(name: NotifyMessageAdded,
                                                object: self, userInfo: [NotiKey: peerUid])
        }
        
        public static func receiveMsg(from: String, gid: String? = nil, msgData: Data, time: Int64) {
                if let msgItem = MessageItem.initByData(msgData, from: from, gid: gid, time: time) {
                        MessageItem.receivedIM(msg: msgItem)
                }
                
        }
        

//        public static func saveUnread(_ msg:[MessageItem]) throws {
//                try CDManager.shared.AddBatch(entity: "CDUnread", m: msg)
//                loadUnread()
//        }

        public static func deleteMsgOneWeek() {
                let owner = Wallet.shared.Addr!
                let limitTime = Int64(Date().timeIntervalSince1970) - 7*86400
                try? CDManager.shared.Delete(entity: "CDUnread",
                                             predicate: NSPredicate(format: "owner == %@ AND unixTime < %@",
                                                                    owner, NSNumber(value: limitTime)))
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
                case .video:
                        uObj.media = self.payload as? NSObject
                default:
                        print("full fill msg: no such type")
                }
                uObj.owner = owner
                uObj.to = self.to
                uObj.unixTime = self.timeStamp
                uObj.status = self.status.rawValue
                uObj.groupId = self.groupId
        }
    
        func initByObj(obj: NSManagedObject) throws {
                guard let uObj = obj as? CDUnread else {
                        throw NJError.coreData("cast to unread item obj failed")
                }
                self.typ = CMT(rawValue: Int(uObj.type)) ?? CMT(rawValue: 1)!

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
                case .video:
                        self.payload = uObj.media as? videoMsg
                default:
                        print("init by msg obj: no such type")
                }
                self.to = uObj.to
                self.timeStamp = uObj.unixTime
                self.status = sendingStatus(rawValue: uObj.status) ?? .sent
                self.groupId = uObj.groupId
        }
    
}

extension MessageList {
        func toString() -> String {
                var str = ""
                for msg in self {
                        switch msg.typ {
                        case .plainTxt:
                                if msg.isOut{
                                        str += "[me]:"
                                }
                                str += "\(msg.payload!)\r\n"
                        case .contact:
                                str += "Contact TODO::\r\n"
                        case .voice:
                                str += "Voice TODO::\r\n"
                        case .location:
                                str += "Location TODO::\r\n"
                        case .image:
                                str += "Image TODO::\r\n"
                        case .video:
                                str += "Video TODO::\r\n"
                        case .file:
                                str += "File TODO::\r\n"
                        }
                }
                return str
        }
}
