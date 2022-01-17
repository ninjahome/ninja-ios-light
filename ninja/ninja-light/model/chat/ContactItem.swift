//
//  ContactItem.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import CoreData
import ChatLib
import SwiftyJSON

class ContactItem:NSObject{
        public static var cache:[String:ContactItem]=[:]
    
        var uid: String?
        var remark: String?
        var owner: String?
        var alias: String?

        var sortPinyin:String?

//        func getSortPinyin() -> String? {
//                guard let nick = self.alias, nick != "" else {
//
//                        return self.uid?.transformToCapitalized()
//                }
//
//                if nick.isIncludeChinese() {
//                        return nick.transformToPinyinHead()
//                } else {
//                        return self.alias?.transformToCapitalized()
//                }
//        }

        public static func GetContact(_ uid:String) -> ContactItem? {
                var obj:ContactItem?
                let owner = Wallet.shared.Addr!
                obj = try? CDManager.shared.GetOne(entity: "CDContact",
                                                   predicate:NSPredicate(format: "uid == %@ AND owner == %@", uid, owner))
                if obj != nil{
                        cache[obj!.uid!] = obj
                }
                return obj
        }
    
        public static func UpdateContact(_ contact:ContactItem) -> NJError?{
                contact.owner = Wallet.shared.Addr!
                if !(IsValidContactID(contact.uid)) {
                        return NJError.contact("invalid ninja address")
                }
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDContact",
                                                m: contact,
                                                predicate: NSPredicate(format: "uid == %@ AND owner == %@", contact.uid!, contact.owner!))
                        cache[contact.uid!] = contact
                } catch let err {
                        return NJError.contact(err.localizedDescription)
                }
                return nil
        }
    
        public static func DelContact(_ uid:String) -> NJError?{
                let owner = Wallet.shared.Addr!
                        do {
                                try CDManager.shared.Delete(entity: "CDContact",
                                                            predicate: NSPredicate(format: "uid == %@ AND owner == %@", uid, owner)
                        )
                        cache.removeValue(forKey: uid)

                        ChatItem.remove(uid)
                        MessageItem.removeRead(uid)
                } catch let err {
                        return NJError.contact(err.localizedDescription)
                }
                return nil
        }
    
        public static func LocalSavedContact() {
                cache = [:]
                guard let owner = Wallet.shared.Addr else{
                        return
                }
                var result:[ContactItem]?
                result = try? CDManager.shared.Get(entity: "CDContact",
                                                   predicate: NSPredicate(format:"owner == %@", owner) ,
                                                   sort: [["alias" : true]])
                guard let arr = result else {
                        return
                }

                for obj in arr {
//                        obj.sortPinyin = obj.getSortPinyin()
                        cache[obj.uid!] = obj
                }
        }
    
        public static func IsValidContactID(_ uid:String?) -> Bool {
                return ChatLibIsValidNinjaAddr(uid)
        }

        public static func CacheArray() -> [ContactItem] {
                return Array(cache.values).sortedByPinyin()!
        }
        
        public static func latestContactDetails() {
                var error: NSError?
                if let data = ChatLibSyncFriendWithDetails(&error),
                        let objJson = try? JSON(data: data) {
                        guard let keys = objJson.dictionaryObject?.keys else {
                                return
                        }
                        for k in keys {
                                let uid = String(k)
                                let peerObj = objJson[uid]
                                
                                let account = peerObj["account"]
                                let accItem = AccountItem.initByJson(account)
                                _ = AccountItem.UpdateOrAddAccount(accItem)
                                
                                let demo = peerObj["demo"]
                                let contactItem = ContactItem.initByJson(demo: demo, uid: uid)
                                _ = ContactItem.UpdateContact(contactItem)
                        }
                }
        }
        
        static func initByJson(demo: JSON, uid: String) -> ContactItem {
                let contactItem = ContactItem()
                contactItem.uid = uid
                contactItem.alias = demo["alias"].string
                contactItem.remark = demo["remark"].string
                contactItem.owner = Wallet.shared.Addr!
                return contactItem
        }

//    public static func GetAvatarColor(by uid: String) -> String {
//        let obj = ContactItem.cache[uid]
//
//        guard let bobj = obj else {
//            return AvatarColors[12]
//        }
//
//        guard let color = bobj.avacolor else {
//            let colorNum = ChatLibIconIndex(uid, 12)
//            let genColor = AvatarColors[Int(colorNum)]
//            obj?.avacolor = genColor
//            _ = UpdateContact(obj!)
//
//            return genColor
//        }
//
//        return color
//
//    }

//    public static func GetAvatarText(by uid: String) -> String {
//        let obj = ContactItem.cache[uid]
//        let addrCut = uid.prefix(2)
//
//        guard let bobj = obj else {
//            return String(addrCut)
//        }
//
//        guard let nick = bobj.nickName, nick != "" else {
//            return String(addrCut)
//        }
//
//        let nickcut = nick.prefix(2)
//        return String(nickcut)
//            return ""
//    }

}

extension ContactItem: ModelObj {
        
        func fullFillObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDContact else{
                        throw NJError.coreData("Cast to CDContact failed")
                }
                cObj.uid = self.uid
                cObj.alias = self.alias
                cObj.remark = self.remark
                cObj.owner = self.owner
        }
    
        func initByObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDContact else{
                        throw NJError.coreData("Cast to CDContact failed")
                }
                self.uid = cObj.uid
                self.alias = cObj.alias
                self.remark = cObj.remark
                self.owner = cObj.owner
        }
    
}
