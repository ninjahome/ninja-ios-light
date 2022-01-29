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
        
        public func isSanme(_ obj:ContactItem?) -> Bool{
                return obj != nil &&
                self.alias == obj?.alias &&
                self.uid == obj?.uid &&
                self.remark == obj?.remark
        }
        
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
        
        public static func AddNewContact(_ contact: ContactItem) -> NJError? {
                
                var error: NSError?
                ChatLibAddFriend(contact.uid, contact.alias, contact.remark, &error)
                if ContactItem.UpdateContact(contact) == nil {
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                object: nil, userInfo:nil)
                }
                if error != nil {
                        print(error!.localizedDescription)
                        return NJError.contact(error!.localizedDescription)
                }
                
                return nil
        }
    
        public static func UpdateContact(_ contact:ContactItem) -> NJError? {
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
    
        public static func IsValidContactID(_ uid:String?) -> Bool {
                return ChatLibIsValidNinjaAddr(uid)
        }

        public static func CacheArray() -> [ContactItem] {
                return Array(cache.values).sortedByPinyin()!
        }
        

        
//        class func updateDetailContact(uid: String) {
//                
//                var err2: NSError?
//                if let friData = ChatLibFriendDetail(uid, &err2) {
//                        let friObj = JSON(friData)
//                        
//                        let acc = friObj["account"]
//                        var accItem:AccountItem?
//                        if acc.exists() {
//                                accItem = AccountItem.initByJson(acc)
//                        } else {
//                                accItem = AccountItem()
//                                accItem!.Addr = uid
//                                accItem!.Balance = 0
//                        }
//                        _ = AccountItem.UpdateOrAddAccount(accItem!)
////                        let jsonCont = JSON(demo)
//                        let demo = friObj["demo"]
//                        let contactItem = ContactItem.initByJson(demo: demo, uid: uid)
//                        _ = ContactItem.UpdateContact(contactItem)
//                }
//        }
// 
        
        
        public static func undateAlias(_ contact: ContactItem) {
                var err: NSError?
                ChatLibUpdateAlias(contact.uid, contact.alias, &err)
                if err != nil {
                        print(err!.localizedDescription)
                }
                
                if ContactItem.UpdateContact(contact) == nil {
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                object: nil, userInfo:nil)
                }
        }
        
        public static func updateRemark(_ contact: ContactItem) {
                var err: NSError?
                ChatLibUpdateRemark(contact.uid, contact.remark, &err)
                if err != nil {
                        print(err!.localizedDescription)
                }
                
                if ContactItem.UpdateContact(contact) == nil {
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                object: nil, userInfo:nil)
                }
        }
        
        public static func updateFriend(_ contact: ContactItem) {
                var err: NSError?
                ChatLibUpdateFriend(contact.uid, contact.alias, contact.remark, &err)
                if err != nil {
                        print(err!.localizedDescription)
                }
                
                if ContactItem.UpdateContact(contact) == nil {
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                object: nil, userInfo:nil)
                }
        }
        
        public static func deleteFriend(_ id: String) {
                var err: NSError?
                ChatLibDeleteFriend(id, &err)
                if err != nil {
                        print(err!.localizedDescription)
                }
                
                if ContactItem.DelContact(id) == nil {
                        NotificationCenter.default.post(name:NotifyContactChanged,
                                                object: nil, userInfo:nil)
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
        
        public static func GetNickName(uid: String) -> String {
                var nickName = uid
                if let contact = ContactItem.cache[uid],
                   let alias = contact.alias, alias != "" {
                        nickName = alias
                } else {
                        if let acc = AccountItem.GetAccount(uid),
                           let nick = acc.NickName, nick != "" {
                                nickName = nick
                        }
                }
                return nickName
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
