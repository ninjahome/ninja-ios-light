//
//  CombineConntact.swift
//  ninja-light
//
//  Created by wesley on 2022/1/29.
//

import Foundation
import SwiftyJSON
import ChatLib

class CombineConntact: NSObject{
        public static var cache:[String:CombineConntact]=[:]
        
        var contact:ContactItem?
        var account:AccountItem?
        var peerID:String=""
        
        public func GetNickName()->String?{
                
                if let alias = self.contact?.alias, !alias.isEmpty{
                        return alias
                }else if let name = self.account?.NickName, !name.isEmpty{
                        return name
                }
                
                return nil
        }
        
        public func updateByUI(alias:String?, remark:String?) -> NJError?{
                guard let contact = self.contact else{
                        let newItem = ContactItem(pid: peerID, alias: alias, remark: remark)
                        if let err = ContactItem.AddNewContact(newItem){
                                return err
                        }
                        self.contact = newItem
                        return nil
                }
                
                var flag:Int8 = 0
                if contact.alias != alias{
                        flag = (flag & 0x1)
                        contact.alias = alias ?? ""
                }
                if contact.remark != remark{
                        flag = (flag & 0x2)
                        contact.remark = remark ?? ""
                }
                
                var err: NSError?
                switch flag{
                case 0:
                        return nil
                case 1:
                        ChatLibUpdateAlias(contact.uid, contact.alias, &err)
                case 2:
                        ChatLibUpdateRemark(contact.uid, contact.remark, &err)
                case 3:
                        ChatLibUpdateFriend(contact.uid, contact.alias, contact.remark, &err)
                        
                default:
                        return nil
                }
                
                if err != nil{
                        return NJError.contact(err!.localizedDescription)
                }
                
                return ContactItem.UpdateContact(contact)
        }
        
        public func removeFromChain()->NJError?{
                
                guard let contact = self.contact else{
                        return NJError.contact("this contact is not on chain")
                }
                if let err =  contact.removeFromChainAndLocalDB(){
                        return err
                        
                }
                
                ChatItem.remove(self.peerID)//TODO:: need a full test
                MessageItem.removeRead(self.peerID)//TODO:: need a full test
                
                CombineConntact.cache[self.peerID] = nil
                
                return nil
        }
        
        public func isVIP()->Bool{
                guard let balance = self.account?.Balance, balance > 0 else{
                        return false
                }
                let validBalance = ChatLibConvertBalance(Int(balance))
                return validBalance > 0.01
        }
        
        
        public func SyncNewItemToChain() -> NJError?{
                
                guard let contact = self.contact else{
                        return NJError.contact("no valid contact to post")
                }
                
                if let err = ContactItem.AddNewContact(contact){
                        return err
                }
                
                guard let account = self.account else{
                        return nil
                }
                
                return AccountItem.UpdateOrAddAccount(account)
        }
        
        public static func ReloadSavedContact() {
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
                        let cc =  CombineConntact()
                        cc.peerID = obj.uid
                        cc.contact = obj
                        
                        
                        var accObj: AccountItem?
                        accObj = try? CDManager.shared.GetOne(entity: "CDAccount",
                                                              predicate: NSPredicate(format: "addr == %@", cc.peerID))
                        if let acc = accObj{
                                cc.account = acc
                        }
                        
                        cache[obj.uid] = cc
                }
        }
        
        public static func CacheArray() -> [CombineConntact] {
                return Array(cache.values)//.sortedByPinyin()!
        }
        
        public static func LoadOneContact(pid:String?) ->CombineConntact?{
                guard let peerID = pid else{
                        return nil
                }
                var err:NSError?
                guard let data = ChatLibFriendDetail(peerID, &err) else{
                        NSLog("------>>> sync friend details err:\(err?.localizedDescription ?? "<->")")
                        return nil
                }
                guard let jsonObj = try? JSON(data: data) else{
                        NSLog("------>>> parse friend details to json object failed")
                        return nil
                }
                let newContact = SaveDataOnChain(json: jsonObj, uid: peerID)
                cache[peerID] = newContact
                return newContact
        }
        
        public static func updatePatialContacts() {
                var error: NSError?
                guard let data = ChatLibAllFriendIDs(&error) else {
                        return
                }
                
                let friendsJson = JSON(data)
                for (friID, subJson):(String, JSON) in friendsJson {
                        let contact = cache[friID]
                        let newItem = ContactItem.initByJson(demo: subJson, uid: friID)
                        
                        if newItem.isSanme(contact?.contact){
                                continue
                        }
                        
                        NSLog("------>>>friend[\(friID)] contact changed and need to sync:")
                        
                        if let c = contact{
                                c.contact = newItem
                                _ = ContactItem.UpdateContact(newItem)
                        }
                        
                        let _ = LoadOneContact(pid: friID)
                }
        }
        
        public static func syncAllContactDataAtOnce() {
                var error: NSError?
                
                guard let data = ChatLibSyncFriendWithDetails(&error)else{
                        NSLog("------>>> ChatLibSyncFriendWithDetails failed:\(error!.localizedDescription)")
                        return
                }
                
                guard let allContactJson = try? JSON(data: data) else{
                        NSLog("------>>> failed to parse the syncing friend data to json dirction")
                        return
                }
                
                for (uid, contact):(String,JSON) in allContactJson {
                        let cc = CombineConntact.SaveDataOnChain(json:contact, uid:uid)
                        cache[uid] = cc
                }
        }
        
        
        public static func SaveDataOnChain(json:JSON, uid:String)->CombineConntact{
                let cc =  CombineConntact()
                
                if json["account"].exists(){
                        let accItem = AccountItem.initByJson(json["account"])
                        let err = AccountItem.UpdateOrAddAccount(accItem)
                        if err != nil{
                                NSLog("------>>> save account detail failed:\(err?.localizedDescription ?? "<->")")
                        }
                        cc.account = accItem
                }
                
                if json["demo"].exists(){
                        let contactItem = ContactItem.initByJson(demo: json["demo"], uid: uid)
                        _ = ContactItem.UpdateContact(contactItem)
                        cc.contact = contactItem
                }
                
                cc.peerID = uid
                
                return cc
        }
}