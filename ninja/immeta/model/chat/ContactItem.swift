//
//  ContactItem.swift
//  immeta
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import CoreData
import ChatLib
import SwiftyJSON

class ContactItem:NSObject{
        
        var uid: String = ""
        var remark: String?
        var alias: String?
        
        //TODO:: sort by alphabet
        var sortPinyin:String?
        
        override init(){
                super.init()
        }
        
        init(pid:String, alias:String?, remark:String?){
                super.init()
                self.uid = pid
                self.alias = alias
                self.remark = remark
        }
        
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
        
        public func removeFromChainAndLocalDB() -> NJError?{
                var err: NSError?
                ChatLibDeleteFriend(self.uid, &err)
                if err != nil {
                        return NJError.contact(err!.localizedDescription)
                }
                
                let owner = Wallet.shared.Addr!
                do {
                        try CDManager.shared.Delete(entity: "CDContact",
                                                    predicate: NSPredicate(format: "uid == %@ AND owner == %@", self.uid, owner)
                        )
                } catch let err {
                        return NJError.contact(err.localizedDescription)
                }
                return nil
        }

        public static func AddNewContact(_ contact: ContactItem) -> NJError? {
                
                var error: NSError?
                ChatLibAddFriend(contact.uid, contact.alias, contact.remark, &error)
                if error != nil{
                        print("------>>>add new contract failed[\(error!.localizedDescription)]")
                        return NJError.contact(error!.localizedDescription)
                }
                return ContactItem.UpdateContact(contact)
        }
        
        public static func UpdateContact(_ contact:ContactItem) -> NJError? {
                let owner = Wallet.shared.Addr!
                if !(IsValidContactID(contact.uid)) {
                        return NJError.contact("invalid ninja address")
                }
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDContact",
                                                            m: contact,
                                                            predicate: NSPredicate(format: "uid == %@ AND owner == %@", contact.uid, owner))
                } catch let err {
                        return NJError.contact(err.localizedDescription)
                }
                return nil
        }
        
        public static func IsValidContactID(_ uid:String?) -> Bool {
                return ChatLibIsValidNinjaAddr(uid)
        }
        
        
        static func initByJson(demo: JSON, uid: String) -> ContactItem {
                return ContactItem(pid: uid, alias: demo["alias"].string, remark: demo["remark"].string)
        }
        
}

extension ContactItem: ModelObj {
        
        func fullFillObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDContact else{
                        throw NJError.coreData("Cast to CDContact failed")
                }
                cObj.uid = self.uid
                cObj.alias = self.alias
                cObj.remark = self.remark
                cObj.owner = Wallet.shared.Addr!
        }
        
        func initByObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDContact else{
                        throw NJError.coreData("Cast to CDContact failed")
                }
                self.uid = cObj.uid!
                self.alias = cObj.alias
                self.remark = cObj.remark
        }
        
}
