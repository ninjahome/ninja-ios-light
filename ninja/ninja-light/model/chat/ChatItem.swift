//
//  ChatItem.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import CoreData

class ChatItem: NSObject{
        public static var CachedChats = LockCache<ChatItem>()

        var cObj:CDChatItem?
        var ItemID:String?
        var ImageData:Data?
        var NickName:String?
        var LastMsg:String?
        var updateTime:Int64 = 0
        var unreadNo:Int = 0
        var isGroup: Bool = false
    
        public static func ReloadChatRoom() {
                var result:[ChatItem]?
                let owner = Wallet.shared.Addr!
                result = try? CDManager.shared.Get(entity: "CDChatItem",
                                                   predicate: NSPredicate(format: "owner == %@", owner),
                                                   sort: [["updateTime" : true]])
                guard let data = result else {
                        return
                }
                
                for obj in data {
                        if obj.isGroup {
                                let group = GroupItem.cache[obj.ItemID!]
                                if group == nil {
                                        ChatItem.remove(obj.ItemID!)
                                        continue
                                }
                        }
        //            CachedChats[obj.ItemID!] = obj
                    CachedChats.setOrAdd(idStr: obj.ItemID!, item: obj)
                }
        
        }

        public static func getTotalUnreadNo() -> Int {
                let items = CachedChats.getValues()
                var total = 0
                for i in items {
                        total += i.unreadNo
                }
                return total
        }
        
        public static func updateLastPeerMsg(peerUid: String, msg: String, time: Int64, unread no: Int) {
                let chat = CachedChats.get(idStr: peerUid) ?? ChatItem.init()
                chat.ItemID = peerUid
                chat.isGroup = false
                
                if chat.updateTime > time {
                        return
                }
                
                if let contact = ContactItem.cache[peerUid] {
                        if let alias = contact.alias {
                                chat.NickName = alias
                        } else {
                                let localAcc = AccountItem.GetAccount(peerUid)
                                chat.NickName = localAcc?.NickName ?? peerUid
                        }
                } else {
                        if let acc = AccountItem.GetAccount(peerUid) {
                                chat.NickName = acc.NickName
                        } else {
                                if let latest = AccountItem.getLatestAccount(addr: peerUid) {
                                        _ = AccountItem.UpdateOrAddAccount(latest)
                                        chat.NickName = latest.NickName
                                }
                        }
                }
                
                chat.updateTime = time
                chat.unreadNo += no
                chat.LastMsg = msg
                
                chat.cObj?.unreadNo = Int32(chat.unreadNo)
                chat.cObj?.lastMsg = chat.LastMsg

                CachedChats.setOrAdd(idStr: peerUid, item: chat)
                
                let owner = Wallet.shared.Addr!
                try? CDManager.shared.UpdateOrAddOne(entity: "CDChatItem",
                                                     m: chat,
                                                     predicate: NSPredicate(format: "uid == %@ AND owner == %@", peerUid, owner))
                
                NotificationCenter.default.post(name: NotifyMsgSumChanged,
                                                    object: self, userInfo:nil)
        }
        
        public static func updateLastGroupMsg(groupId: String, msg: String, time: Int64, unread no:Int) {
                let chat = CachedChats.get(idStr: groupId) ?? ChatItem.init()
                chat.ItemID = groupId
                chat.isGroup = true
                
                if chat.updateTime > time {
                        return
                }
                
                if let groupItem = GroupItem.cache[groupId] {
                        chat.NickName = groupItem.groupName
                } else {
                        let gItem = GroupItem.syncGroup(groupId)
                        chat.NickName = gItem?.groupName
                }
                
                chat.updateTime = time
                chat.unreadNo += no
                chat.LastMsg = msg
                
                chat.cObj?.unreadNo = Int32(chat.unreadNo)
                chat.cObj?.lastMsg = chat.LastMsg

                CachedChats.setOrAdd(idStr: groupId, item: chat)
                
                let owner = Wallet.shared.Addr!
                try? CDManager.shared.UpdateOrAddOne(entity: "CDChatItem",
                                                     m: chat,
                                                     predicate: NSPredicate(format: "groupId == %@ AND owner == %@", groupId, owner))
                NotificationCenter.default.post(name:NotifyMsgSumChanged,
                                                    object: self, userInfo:nil)
        }
        
        public static func SortedArra() -> [ChatItem] {
                var sortedArray = CachedChats.getValues()
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

                self.unreadNo = 0
                self.cObj?.unreadNo = 0
                NotificationCenter.default.post(name:NotifyMsgSumChanged,
                                                object: self,
                                                userInfo:nil)
        }

        public static func remove(_ uid:String) {
                let owner = Wallet.shared.Addr!
                try? CDManager.shared.Delete(entity: "CDChatItem",
                                             predicate: NSPredicate(format: "owner == %@ AND (uid == %@ OR groupId == %@)", owner, uid, uid))
                CachedChats.delete(idStr: uid)
        }
}

extension ChatItem: ModelObj {

        func fullFillObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDChatItem else {
                        throw NJError.coreData("cast to chat item obj failed")
                }

                let owner = Wallet.shared.Addr!

                if isGroup {
                        cObj.groupId = self.ItemID
                } else {
                        cObj.uid = self.ItemID
                }

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
                
                if let gid = cObj.groupId {
                        self.ItemID = gid
                        self.isGroup = true
                } else {
                        self.ItemID = cObj.uid
                }
                
                self.LastMsg = cObj.lastMsg
                self.updateTime = cObj.updateTime
                self.unreadNo = Int(cObj.unreadNo)
                self.cObj = cObj
                
                if let contact = ContactItem.cache[self.ItemID!],
                   let alias = contact.alias, alias != "" {
                        self.NickName = alias
                } else {
                        let acc = AccountItem.GetAccount(self.ItemID!)
                        self.NickName = acc?.NickName ?? self.ItemID!
                }

                if let group = GroupItem.cache[self.ItemID!] {
                        self.NickName = group.groupName
                }
        }
}
