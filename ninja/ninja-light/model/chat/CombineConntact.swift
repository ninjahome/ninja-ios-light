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
        
        var contact:ContactItem?
        var account:AccountItem?
        var peerID:String=""
        
        public static var cache:[String:CombineConntact]=[:]
        
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
                        cc.peerID = obj.uid!
                        cc.contact = obj
                        
                        
                        var accObj: AccountItem?
                        accObj = try? CDManager.shared.GetOne(entity: "CDAccount",
                                                              predicate: NSPredicate(format: "addr == %@", cc.peerID))
                        if let acc = accObj{
                                cc.account = acc
                        }
                        
                        cache[obj.uid!] = cc
                }
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
                        
                        var err:NSError?
                        guard let data = ChatLibFriendDetail(friID, &err) else{
                                NSLog("------>>> sync friend details err:\(err?.localizedDescription ?? "<->")")
                                continue
                        }
                        guard let jsonObj = try? JSON(data: data) else{
                                NSLog("------>>> parse friend details to json object failed")
                                continue
                        }
                        let newContact = SaveDataOnChain(json: jsonObj, uid: friID)
                        cache[friID] = newContact
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
                        _ = CombineConntact.SaveDataOnChain(json:contact, uid:uid)
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
                
                cache[uid]=cc
                
                return cc
        }
}
