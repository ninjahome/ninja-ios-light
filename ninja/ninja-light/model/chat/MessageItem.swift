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

protocol IMPayLoad {
        func wrappedToProto()->Data?
}

class MessageItem: NSObject {
        public static let NotiKey = "peerUid"
        public static let MaxItemNoPerID = 1000
        
        var timeStamp: Int64 = ChatLibNowInMilliSeconds()
        var from: String = ""
        var to: String = ""
        var typ: CMT = .plainTxt
        var payload: IMPayLoad?
        var isOut: Bool = false
        var groupId: String?
        var status: sendingStatus = .sent
        
        public static var cache = LockCache<MessageList>()
        
        override init() {
                super.init()
        }
        
        init(to:String, data:IMPayLoad, typ:CMT = .plainTxt, gid:String?=nil) {
                super.init()
                
                from = Wallet.shared.Addr!
                isOut = true
                groupId = gid
                status = .sending
                self.typ = typ
                self.to = to
                self.payload = data
        }
        
        private func parseProtoMsgData(data:Data)->Error?{
                var err:NSError?
                ChatLibUnwrapProMsg(data, self, &err)
                if let e = err{
                        return e
                }
                return nil
        }
        
        public static func initByData(_ data: Data, from: String, gid: String? = nil, time: Int64) -> MessageItem? {
                guard data.count > 2 else{
                        print("------>>> empty message data")
                        return nil
                }
                
                let msgItem = MessageItem()
                if let e = msgItem.parseProtoMsgData(data: data){
                        print("------>>> [parseProtoMsgData]",e)
                        return nil
                }
                msgItem.from = from
                msgItem.timeStamp = time
                msgItem.groupId = gid
                
                return msgItem
        }
        
      
        
        //pull to load more unread message
        public static func loadUnread() {
                guard let owner = Wallet.shared.Addr else {
                        return
                }
                var result:[MessageItem]?
                result = try? CDManager.shared.Get(entity: "CDUnread",
                                                   predicate: NSPredicate(format: "owner == %@", owner),
                                                   sort: [["unixTime" : true]],
                                                   limit: MaxItemNoPerID)
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
                                        peerUid = msg.to
                                } else {
                                        peerUid = msg.from
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
                                                             predicate: NSPredicate(format: "owner == %@ AND to == %@ AND unixTime == %@", owner, to, NSNumber(value: mid)))
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
                case .location:
                        return "[Location]"
                case .contact:
                        return "[Contact]"
                case .image:
                        return "[Image]"
                case .file:
                        return "[File]"
                case .unknown:
                        return "unknown"
                }
        }
                
        public static func syncNewIMToDisk(msg:MessageItem) -> Error?{
                do{
                        var msgList = cache.get(idStr: msg.to)
                        if msgList == nil {
                                msgList = []
                        }
                        msgList?.append(msg)
                        cache.setOrAdd(idStr: msg.to, item: msgList)
                        try CDManager.shared.AddEntity(entity: "CDUnread", m: msg)
                        return nil
                }catch let err{
                        return err
                }
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
                        NotificationCenter.default.post(name: NotifyMessageAdded,
                                                        object: self, userInfo: [NotiKey: peerUid!])
                        for item in msgs {
                                print(item.status)
                                print(item.typ)
                        }
                }
                
        }
        
        private static func cacheNewMsg(pid:String, msg:MessageItem){
                var msgList = cache.get(idStr: pid)
                if msgList == nil {
                        msgList = []
                }
                
                msgList?.append(msg)
                msgList?.sort(by: { (a, b) -> Bool in
                        return a.timeStamp < b.timeStamp
                })
                cache.setOrAdd(idStr: pid, item: msgList)
                
                NotificationCenter.default.post(name: NotifyMessageAdded,
                                                object: self, userInfo: [NotiKey: pid])
        }
        
        public static func receiveMsg(from: String, gid: String? = nil, msgData: Data, time: Int64) {
                
                guard let msgItem = MessageItem.initByData(msgData, from: from, gid: gid, time: time) else{
                        return
                }
                
                do{
                        try CDManager.shared.AddEntity(entity: "CDUnread", m: msgItem)
                        
                }catch let err{
                        print("------>>> save new message failed:[\(err.localizedDescription)]")
                        return
                }
                
                let peerUid = gid ?? from
                cacheNewMsg(pid: peerUid, msg: msgItem)
                
                ChatItem.updateLatestrMsg(pid: peerUid,
                                          msg: msgItem.coinvertToLastMsg(),
                                          time: msgItem.timeStamp,
                                          unread: 1,
                                          isGrp: gid != nil)
        }
        
        public static func deleteMsgOneWeek() {
                let owner = Wallet.shared.Addr!
                let limitTime = Int64(Date().timeIntervalSince1970) - 7*86400
                try? CDManager.shared.Delete(entity: "CDUnread",
                                             predicate: NSPredicate(format: "owner == %@ AND unixTime < %@",
                                                                    owner, NSNumber(value: limitTime)))
        }
        public static func prepareMessage() {
                deleteMsgOneWeek()
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
                        uObj.message = (self.payload as? txtMsg)?.txt
                case .image:
                        uObj.image = (self.payload as? imgMsg)?.content
                case .voice:
                        uObj.media = self.payload as? NSObject
                case .location:
                        uObj.media = self.payload as? NSObject
                case .file:
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
                
                self.from = uObj.from!
                self.isOut = uObj.isOut
                
                switch self.typ {
                case .plainTxt:
                        self.payload = txtMsg.init(txt:uObj.message ?? "")
                case .image:
                        self.payload = imgMsg.init(data:uObj.image ?? Data())
                case .voice:
                        self.payload = uObj.media as? audioMsg
                case .location:
                        self.payload = uObj.media as? locationMsg
                case .file:
                        self.payload = uObj.media as? fileMsg
                default:
                        print("init by msg obj: no such type")
                }
                self.to = uObj.to ?? "<->"//TODO::
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
                        case .file:
                                str += "File TODO::\r\n"
                        case .unknown:
                                str += "unknown TODO::\r\n"
                        }
                }
                return str
        }
}

extension MessageItem:ChatLibUnwrapCallbackProtocol{
        func file(_ n: String?, t: Int32, d: Data?) {
                self.typ = .file
                let filTyp = FileTyp.init(rawValue: t)
                switch filTyp{
                case .video:
                        self.payload = videoMsg(name: n, data: d)
                default:
                        self.payload = fileMsg(name:n, data:d ?? Data())
                }
        }
        
        func img(_ d: Data?) {
                self.typ = .image
                self.payload = imgMsg(data: d ?? Data())
        }
        
        func location(_ n: String?, lo: Double, la: Double) {
                self.typ = .location
                self.payload = locationMsg(name:n, long:lo, lat:la)
        }
        
        func txt(_ s: String?) {
                self.typ = .plainTxt
                self.payload = txtMsg(txt: s ?? "")
        }
        
        func voice(_ l: Int32, d: Data?) {
                self.typ = .voice
                self.payload = audioMsg(data: d ?? Data(), len: Int(l))
        }
}
