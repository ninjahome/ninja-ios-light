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
