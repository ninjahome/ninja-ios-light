//
//  ChatItem.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import CoreData

class ChatItem: NSObject{
        public static var ChatItemCache:[String: ChatItem]  = [:]
        
        public static var TotalUnreadNo = 0
        public static var CurrentPID:String = ""
        private static let noLock = NSLock()
        
        var cObj:CDChatItem?
        var ItemID:String = ""
        var LastMsg:String?
        var updateTime:Int64 = 0
        var unreadNo:Int = 0
        var isGroup: Bool = false
        
        override init(){
                super.init()
        }
        
        init(id:String, time:Int64, msg:String, isGrp:Bool, unread:Int=1){
                super.init()
                self.ItemID = id
                self.updateTime = time
                self.LastMsg = msg
                self.isGroup = isGrp
                self.unreadNo = unread
        }
        
        
        public static func ReloadChatRoom() {
                var result:[ChatItem]?
                let owner = Wallet.shared.Addr!
                result = try? CDManager.shared.Get(entity: "CDChatItem",
                                                   predicate: NSPredicate(format: "owner == %@", owner),
                                                   sort: [["updateTime" : true]])
                guard let data = result else {
                        return
                }
                noLock.lock()
                defer{
                        noLock.unlock()
                }
                TotalUnreadNo = 0
                for obj in data {
                        TotalUnreadNo += obj.unreadNo
                        ChatItemCache[obj.ItemID] = obj
                }
        }

        public static func updateLatestrMsg(pid: String, msg: String, time: Int64, unread no: Int, isGrp:Bool) {
                var unreadNo = no
                if pid == CurrentPID{
                        unreadNo = 0
                }
                
                noLock.lock()
                defer{
                        noLock.unlock()
                }
                var chat = ChatItemCache[pid]
                if let c = chat{
                        if c.updateTime > time {
                                return
                        }
                        c.updateTime = time
                        c.LastMsg = msg
                        c.unreadNo += unreadNo
                        c.cObj?.unreadNo = Int32(c.unreadNo)
                        c.cObj?.lastMsg = c.LastMsg
                        c.cObj?.updateTime = time
                }else{
                        chat = ChatItem.init(id: pid, time: time, msg: msg, isGrp: isGrp, unread:no)
                        let owner = Wallet.shared.Addr!
                        try? CDManager.shared.UpdateOrAddOne(entity: "CDChatItem",
                                                             m: chat!,
                                                             predicate: NSPredicate(format: "peerID == %@ AND owner == %@", pid, owner))
                }
                
                ChatItemCache[pid] = chat
                TotalUnreadNo = TotalUnreadNo + unreadNo
                
                NotificationCenter.default.post(name: NotifyMsgSumChanged,
                                                object: pid, userInfo:nil)
        }
        
        
        public static func SortedArra() -> [ChatItem] {
                noLock.lock()
                defer{
                        noLock.unlock()
                }
                
                var sortedArray = Array(ChatItemCache.values)
                guard sortedArray.count > 1 else {
                        return sortedArray
                }
                sortedArray.sort { (a, b) -> Bool in
                        return a.updateTime > b.updateTime
                }
                return sortedArray
        }
        
        func resetUnread(){
                guard self.unreadNo != 0 else {
                        return
                }
                
                ChatItem.noLock.lock()
                ChatItem.TotalUnreadNo = ChatItem.TotalUnreadNo -  self.unreadNo
                if ChatItem.TotalUnreadNo < 0{
                        ChatItem.TotalUnreadNo = 0
                }
                ChatItem.noLock.unlock()
                
                self.unreadNo = 0
                self.cObj?.unreadNo = 0
        }
        
        public static func remove(_ pid:String) {
                noLock.lock()
                defer{
                        noLock.unlock()
                }
                let owner = Wallet.shared.Addr!
                try? CDManager.shared.Delete(entity: "CDChatItem",
                                             predicate: NSPredicate(format: "owner == %@ AND peerID == %@ ", owner, pid))
                ChatItemCache.removeValue(forKey: pid)
        }
        public static func deleteAll(){
                noLock.lock()
                defer{
                        noLock.unlock()
                }
                ChatItemCache.removeAll()
        }
}

extension ChatItem: ModelObj {
        
        func fullFillObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDChatItem else {
                        throw NJError.coreData("cast to chat item obj failed")
                }
                
                let owner = Wallet.shared.Addr!
                
                if isGroup {
                        cObj.isGrp = true
                } else {
                        cObj.isGrp = false
                }
                
                cObj.peerID = self.ItemID
                cObj.owner = owner
                cObj.lastMsg = self.LastMsg
                cObj.updateTime = self.updateTime
                cObj.unreadNo = Int32(self.unreadNo)
                self.cObj = cObj
        }
        
        func initByObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDChatItem else {
                        throw NJError.coreData("cast to chat item obj failed")
                }
                guard let pid = cObj.peerID else{
                        throw NJError.coreData("the chat item has no peer id")
                }
                self.ItemID = pid
                self.isGroup = cObj.isGrp
                self.LastMsg = cObj.lastMsg
                self.updateTime = cObj.updateTime
                self.unreadNo = Int(cObj.unreadNo)
                self.cObj = cObj
        }
}
