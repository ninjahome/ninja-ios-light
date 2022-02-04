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

typealias MsgCacheMap = [Int64:MessageItem]

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
        
        public static var msgCache:[String:MsgCacheMap] = [:]
        public static var msgLock = NSLock()
        
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
        
        public static func cacheItem(pid:String, item:MessageItem){
                msgLock.lock()
                cacheItemWithoutLock(pid: pid, item: item)
                msgLock.unlock()
        }
        
        public static func cacheItemWithoutLock(pid:String, item:MessageItem){
                
                var map = msgCache[pid]
                if map == nil{
                        map = MsgCacheMap.init()
                        msgCache[pid] = map
                }
                map![item.timeStamp] = item
                msgCache.updateValue(map!, forKey: pid)
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
                
                msgLock.lock()
                defer{
                        msgLock.unlock()
                }
                msgCache.removeAll()
                
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
                        
                        cacheItemWithoutLock(pid: peerUid, item: msg)
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
                msgLock.lock()
                defer{
                        msgLock.unlock()
                }
                msgCache.removeValue(forKey: uid)
                let owner = Wallet.shared.Addr!
                try? CDManager.shared.Delete(entity: "CDUnread",
                                             predicate: NSPredicate(format: "owner == %@ AND (from == %@ OR to == %@)",
                                                                    owner, uid, uid))
        }
        
        public static func removeAllRead() {
                msgLock.lock()
                defer{
                        msgLock.unlock()
                }
                
                msgCache.removeAll()
                let owner = Wallet.shared.Addr!
                try? CDManager.shared.Delete(entity: "CDUnread",
                                             predicate: NSPredicate(format: "owner == %@", owner))
                FileManager.cleanupTmpDirectory()
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
        
        
        public static func updateSendResult(msgid: Int64, to: String, success: Bool){
                if msgid < 0{
                        NotificationCenter.default.post(name: NotifyMessageSendResult,
                                                        object: msgid, userInfo: nil)
                        return
                }
                msgLock.lock()
                defer{
                        msgLock.unlock()
                }
                
                guard let msg = msgCache[to]?[msgid] else{
                        return
                }
                
                if success {
                        msg.status = .sent
                }else{
                        msg.status = .faild
                }
                
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDUnread", m: msg,
                                                            predicate: NSPredicate(format: "unixTime == %@",NSNumber(value: msg.timeStamp)))
                        
                        CDManager.shared.saveContext()
                }catch let err{
                        print("------>>> update message sent result:[\(err.localizedDescription)]")
                        return
                }
                
                NotificationCenter.default.post(name: NotifyMessageSendResult,
                                                object: msgid,
                                                userInfo: nil)
        }
        
        public static func processNewMessage(pid:String, msg:MessageItem, unread:Int) -> Error?{
                do{
                        cacheItem(pid: pid, item: msg)
                        
                        try CDManager.shared.AddEntity(entity: "CDUnread", m: msg)
                        
                        ChatItem.updateLatestrMsg(pid: pid,
                                                  msg: msg.coinvertToLastMsg(),
                                                  time: msg.timeStamp,
                                                  unread: unread,
                                                  isGrp: msg.groupId != nil)
                        return nil
                }catch let err{
                        print("------>>> save new message failed:[\(err.localizedDescription)]")
                        return err
                }
        }
        
        public static func receiveMsg(from: String, gid: String? = nil, msgData: Data, time: Int64) {
                
                guard let msgItem = MessageItem.initByData(msgData, from: from, gid: gid, time: time) else{
                        print("------>>> receied invalid message", from, gid ?? "<->", msgData.count)
                        return
                }
                
                
                let peerUid = gid ?? from
                guard let e = processNewMessage(pid: peerUid, msg: msgItem, unread: 1)else{
                        return
                }
                
                print("------>>>process received message err:=>",e)

                NotificationCenter.default.post(name: NotifyMessageAdded,
                      object: self, userInfo: [NotiKey: peerUid])
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
        
        public static func SortedArray(pid:String) -> [MessageItem] {
                msgLock.lock()
                defer{
                        msgLock.unlock()
                }
                guard let msges = msgCache[pid] else {
                        return []
                }
                
                var sortedArray = Array(msges.values)
                guard sortedArray.count > 1 else {
                        return sortedArray
                }
                sortedArray.sort { (a, b) -> Bool in
                        return a.timeStamp < b.timeStamp
                }
                return sortedArray
        }
        
        public static func deleteAll(){
                msgLock.lock()
                defer{
                        msgLock.unlock()
                }
                msgCache.removeAll()
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
