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
        
        public static let MaxMsgLiftTime = Double(7*86400)
        public static let TimeOutDuration = 1000 * 60 * 2
        public static let NotiKey = "peerUid"
        public static let ItemNoPerPull = 100
        
        var timeStamp: Int64 = ChatLibNowInMilliSeconds()
        var from: String = ""
        var to: String = ""
        var typ: CMT = .plainTxt
        var payload: IMPayLoad?
        var isOut: Bool = false
        var groupId: String?
        var status: sendingStatus = .sent
        var uObj:CDUnread? = nil
        
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
        
        public static func preLoadMsgAtAppLaunch() {
                guard let owner = Wallet.shared.Addr else {
                        return
                }
                let pids = ChatItem.Pids()
                guard pids.count > 0 else{
                        return
                }
                msgCache.removeAll()
                
                for (pid, item) in pids{
                        
                        var result:[MessageItem]?
                        
                        var messageOfPeer = msgCache[pid]
                        if messageOfPeer == nil{
                                messageOfPeer = MsgCacheMap()
                                msgCache[pid] = messageOfPeer
                        }
                        var predicate:NSPredicate!
                        if item.isGroup{
                                predicate = NSPredicate(format: "owner == %@ AND groupId == %@", owner, pid)
                        }else{
                                predicate = NSPredicate(format: "owner == %@ AND (from == %@ OR to == %@)",
                                                        owner, pid, pid)
                        }
                        
                        
                        result = try? CDManager.shared.Get(
                                entity: "CDUnread",
                                predicate:predicate,
                                sort: [["unixTime" : false]],
                                limit: ItemNoPerPull)
                        
                        
                        guard let data = result, !data.isEmpty else{
                                continue
                        }
                        for msg in data {
                                messageOfPeer![msg.timeStamp] = msg
                        }
                        msgCache.updateValue(messageOfPeer!, forKey: pid)
                }
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
                msgCache.removeAll()
                msgLock.unlock()
                
                FileManager.cleanupTmpDirectory()
                let owner = Wallet.shared.Addr!
                do{
                        try CDManager.shared.Delete(entity: "CDUnread",
                                                    predicate: NSPredicate(format: "owner == %@", owner))
                }catch let err{
                        print("------>>>clean unread message failed:=>", err)
                }
        }
        
        func coinvertToLastMsg() -> String{
                switch self.typ {
                case .plainTxt:
                        return "[Text]".locStr
                case .voice:
                        return "[Voice]".locStr
                case .location:
                        return "[Location]".locStr
                case .image:
                        return "[Image]".locStr
                case .file:
                        return "[File]".locStr
                case .unknown:
                        return "Unknown".locStr
                case .contact:
                        return "[Contact]".locStr
                case .videoWithHash:
                        return "[Video]".locStr
                case .redPacket:
                        return "[Red Packet]".locStr
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
                        msg.updateSendStatus(status: .sent)
                }else{
                        msg.updateSendStatus(status: .faild)
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
                        CDManager.shared.saveContext()
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
                if let e = processNewMessage(pid: peerUid, msg: msgItem, unread: 1){
                        print("------>>>process received message err:=>",e)
                        return
                }
                
                NotificationCenter.default.post(name: NotifyMessageAdded,
                                                object: self, userInfo: [NotiKey: peerUid])
        }
        
        public static func deleteMsgOneWeek() {
                let owner = Wallet.shared.Addr!
                let limitTime = Date().timeIntervalSince1970 - MaxMsgLiftTime
                try? CDManager.shared.Delete(entity: "CDUnread",
                                             predicate: NSPredicate(format: "owner == %@ AND unixTime < %@",
                                                                    owner, NSNumber(value: limitTime*1000)))
                FileManager.removeTmpDirectoryExpire()
        }
        
        public static func prepareMessage() {
                deleteMsgOneWeek()
                preLoadMsgAtAppLaunch()
        }
        
        public static func loadHistoryByPid(pid:String, timeStamp:Int64?, isGroup:Bool)-> [MessageItem]? {
                var result:[MessageItem]?
                let owner = Wallet.shared.Addr!
                var time:Int64
                if nil == timeStamp{
                        time = ChatLibNowInMilliSeconds()
                }else{
                        time = timeStamp!
                }
                var predicate:NSPredicate!
                if isGroup{
                        predicate = NSPredicate(format: "owner == %@ AND groupId == %@ AND unixTime < %@",
                                                owner, pid, NSNumber(value: time))
                }else{
                        predicate = NSPredicate(format: "owner == %@ AND (from == %@ OR to == %@ AND unixTime < %@)",
                                                owner, pid, pid, NSNumber(value: time))
                }
                
                result = try? CDManager.shared.Get(
                        entity: "CDUnread",
                        predicate: predicate,
                        sort: [["unixTime" : false]],
                        limit: ItemNoPerPull)
                return result?.reversed()
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
        
        func updateSendStatus(status:sendingStatus){
                self.status = status
                self.uObj?.status = status.rawValue
                CDManager.shared.saveContext()
        }
        
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
                case .image, .voice, .location, .file, .videoWithHash:
                        uObj.media = self.payload as? NSObject
                default:
                        print("full fill msg: no such type")
                }
                uObj.owner = owner
                uObj.to = self.to
                uObj.unixTime = self.timeStamp
                uObj.status = self.status.rawValue
                
                if self.status == .sending{
                        let now = ChatLibNowInMilliSeconds()
                        if now - self.timeStamp > MessageItem.TimeOutDuration{
                                self.status = .faild
                                uObj.status = self.status.rawValue
                        }
                }
                
                uObj.groupId = self.groupId
                self.uObj = uObj
        }
        
        func initByObj(obj: NSManagedObject) throws {
                guard let uObj = obj as? CDUnread else {
                        throw NJError.coreData("cast to unread item obj failed")
                }
                
                self.from = uObj.from!
                self.isOut = uObj.isOut
                self.typ = CMT(rawValue: Int(uObj.type)) ?? CMT(rawValue: 1)!
                
                switch self.typ {
                case .plainTxt:
                        self.payload = txtMsg.init(txt:uObj.message ?? "")
                case .image:
                        self.payload = uObj.media as? imgMsg //imgMsg.init(data:uObj.image ?? Data(), has: uObj.ha)
                case .voice:
                        self.payload = uObj.media as? audioMsg
                case .location:
                        self.payload = uObj.media as? locationMsg
                case .file:
                        self.payload = uObj.media as? fileMsg
                case .videoWithHash:
                        self.payload = uObj.media as? videoMsgWithHash
                default:
                        print("------>>>init by msg obj: no such type")
                }
                self.to = uObj.to ?? "<->"//TODO::
                self.groupId = uObj.groupId
                self.uObj = uObj
                
                
                self.timeStamp = uObj.unixTime
                self.status = sendingStatus(rawValue: uObj.status) ?? .sent
                if self.status == .sending{
                        let now = ChatLibNowInMilliSeconds()
                        if now - self.timeStamp > MessageItem.TimeOutDuration{
                                self.status = .faild
                                uObj.status = self.status.rawValue
                        }
                }
        }
}


extension MessageItem:ChatLibUnwrapCallbackProtocol{
        func contact(_ u: String?, r: String?) {
                self.typ = .contact
                self.payload = contactMsg(uid: u ?? "", recommendor: r)
        }
        
        func redPacket(_ f: String?, t: String?, a: Int64) {
                self.typ = .redPacket
                self.payload = redPacketMsg(from: f ?? "", to: t ?? "", amount: a)
        }
        
        
        func video(withHash d: Data?, k: Data?, h: String?, horiz:Bool) {
                self.typ = .videoWithHash
                self.payload = videoMsgWithHash(thumb: d ?? Data(), has: h ?? "", isHorizon: horiz, key: k)
        }
        
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
        
        func img(_ d: Data?,k: Data?, h:String?) {
                self.typ = .image
                self.payload = imgMsg(data: d ?? Data(), has: h ?? "", key: k)
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
