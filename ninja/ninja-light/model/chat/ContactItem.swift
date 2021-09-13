//
//  ContactItem.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import CoreData
import ChatLib

class ContactItem:NSObject{
    public static var cache:[String:ContactItem]=[:]
    
    var uid:String?
    var nickName:String?
    var avatar:Data?
    var remark:String?
    var owner:String?
    var avacolor:String?

    var sortPinyin:String?

    func getSortPinyin() -> String? {
        guard let nick = self.nickName, nick != "" else {
            return self.uid?.transformToCapitalized()
        }
        
        if nick.isIncludeChinese() {
            return nick.transformToPinyinHead()
            
        } else {
            return self.nickName?.transformToCapitalized()
        }
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
    
    public static func UpdateContact(_ contact:ContactItem) -> NJError?{
        contact.owner = Wallet.shared.Addr!
        if !(ChatLib.ChatLibIsValidNinjaAddr(contact.uid)) {
            return NJError.contact("invalid ninja address")
        }
        do {
            try CDManager.shared.UpdateOrAddOne(entity: "CDContact",
                                                m: contact,
                                                predicate: NSPredicate(format: "uid == %@ AND owner == %@", contact.uid!, contact.owner!))
                
            cache[contact.uid!] = contact
        }catch let err {
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
        }catch let err{
            return NJError.contact(err.localizedDescription)
        }
        return nil
    }
    
    public static func LocalSavedContact() {
        guard let owner = Wallet.shared.Addr else{
            return
        }
        var result:[ContactItem]?
        result = try? CDManager.shared.Get(entity: "CDContact",
                                           predicate: NSPredicate(format:"owner == %@", owner) ,
                                           sort: [["nickName" : true]])
        guard let arr = result else {
            return
        }
  
        for obj in arr {
            obj.sortPinyin = obj.getSortPinyin()
            cache[obj.uid!] = obj
        }
    }
    
    public static func IsValidContactID(_ uid:String) -> Bool {
            return ChatLib.ChatLibIsValidNinjaAddr(uid)
    }

    public static func CacheArray() -> [ContactItem] {
        return Array(cache.values).sortedByPinyin()!
    }

    public static func GetAvatarColor(by uid: String) -> String {
        let obj = ContactItem.cache[uid]
        
        guard let bobj = obj else {
            return AvatarColors[12]
        }
        
        guard let color = bobj.avacolor else {
            let colorNum = ChatLib.ChatLibIconIndex(uid, 12)
            let genColor = AvatarColors[Int(colorNum)]
            obj?.avacolor = genColor
            _ = UpdateContact(obj!)
            
            return genColor
        }
        
        return color
    
    }

    public static func GetAvatarText(by uid: String) -> String {
        let obj = ContactItem.cache[uid]
        let addrCut = uid.prefix(2)
        
        guard let bobj = obj else {
            return String(addrCut)
        }
        
        guard let nick = bobj.nickName, nick != "" else {
            return String(addrCut)
        }
        
        let nickcut = nick.prefix(2)
        return String(nickcut)

    }

}

extension ContactItem: ModelObj {
        
    func fullFillObj(obj: NSManagedObject) throws {
        guard let cObj = obj as? CDContact else{
            throw NJError.coreData("Cast to CDContact failed")
        }
        cObj.uid = self.uid
        cObj.nickName = self.nickName
        cObj.remark = self.remark
        cObj.avatar = self.avatar
        cObj.owner = self.owner
        cObj.avaColor = self.avacolor
        
    }
    
    func initByObj(obj: NSManagedObject) throws {
        guard let cObj = obj as? CDContact else{
            throw NJError.coreData("Cast to CDContact failed")
        }
        self.uid = cObj.uid
        self.nickName = cObj.nickName
        self.avatar = cObj.avatar
        self.remark = cObj.remark
        self.owner = cObj.owner
        self.avacolor = cObj.avaColor
    }
    
}
