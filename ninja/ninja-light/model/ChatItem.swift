//
//  ChatItem.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import CoreData

class ChatItem:NSObject{
        
        public static var CachedChats:[String:ChatItem] = [:]
        var cObj:CDChatItem?
        var ItemID:String?
        var ImageData:Data?
        var NickName:String?
        var LastMsg:String?
        var updateTime:Int64 = 0
        var unreadNo:Int = 0
        
        override init() {
                super.init()
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
                
                for obj in data{
                        CachedChats[obj.ItemID!] = obj
                }
        }
        
        public static func updateLastMsg(peerUid:String, msg:String, time:Int64, unread no:Int){
                var chat = CachedChats[peerUid]
                if chat == nil{
                        chat = ChatItem.init()
                        chat!.ItemID = peerUid
                        chat!.updateTime = time
                        CachedChats[peerUid] = chat
                        try? CDManager.shared.AddEntity(entity: "CDChatItem", m: chat!)
                }
                
                if let contact = ContactItem.cache[peerUid]{
                        chat!.NickName = contact.nickName
                        chat!.ImageData = contact.avatar
                        chat?.updateTime = time
                }
                
                if chat!.updateTime > time {
                        return
                }
                
                chat!.unreadNo += no
                chat!.LastMsg = msg
                chat!.cObj?.unreadNo = Int32(chat!.unreadNo)
                chat!.cObj?.lastMsg = chat!.LastMsg
            try? CDManager.shared.UpdateOrAddOne(entity: "CDChatItem", m: chat!)
                NotificationCenter.default.post(name:NotifyMsgSumChanged,
                                                object: self, userInfo:nil)
        }
        
        public static func updateAllLastMsg(msg:[String:ChatItem])throws {
                
                let array = Array(msg.values)
                guard array.count > 0 else {
                        return
                }
                
                try CDManager.shared.AddBatch(entity: "CDChatItem", m: array)
                for (uid, obj) in msg{
                        updateLastMsg(peerUid: uid, msg: obj.LastMsg!, time: obj.updateTime, unread: obj.unreadNo)
                }
                
                NotificationCenter.default.post(name:NotifyMsgSumChanged,
                                                object: self, userInfo:nil)
        }
        
        public static func SortedArra() -> [ChatItem]{
                var sortedArray:[ChatItem] = []
                
                guard CachedChats.count > 0 else {
                        return sortedArray
                }
                
                for (_, item) in CachedChats{
                        sortedArray.append(item)
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
                                                object: self, userInfo:nil)
        }
        
        public static func remove(_ uid:String){
                let owner = Wallet.shared.Addr!
                try? CDManager.shared.Delete(entity: "CDChatItem",
                                        predicate: NSPredicate(format: "owner == %@ AND uid == %@", owner, uid))
                CachedChats.removeValue(forKey: uid)
        }
}

extension ChatItem:ModelObj{
        
        func fullFillObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDChatItem else {
                        throw NJError.coreData("cast to chat item obj failed")
                }
                
                let owner = Wallet.shared.Addr!
                cObj.owner = owner
                cObj.uid = self.ItemID
                cObj.lastMsg = self.LastMsg
                cObj.updateTime = self.updateTime
                cObj.unreadNo = Int32(self.unreadNo)
                self.cObj = cObj
        }
        
        func initByObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDChatItem else {
                        throw NJError.coreData("cast to chat item obj failed")
                }
                
                self.ItemID = cObj.uid
                self.LastMsg = cObj.lastMsg
                self.updateTime = cObj.updateTime
                self.unreadNo = Int(cObj.unreadNo)
                self.cObj = cObj
                
                if let contact = ContactItem.cache[self.ItemID!]{
                        self.NickName = contact.nickName
                        self.ImageData = contact.avatar
                }
        }
}
