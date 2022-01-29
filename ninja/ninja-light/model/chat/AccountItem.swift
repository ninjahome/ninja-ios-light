//
//  AccountItem.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/22.
//

import Foundation
import CoreData
import ChatLib
import SwiftyJSON

class AccountItem: NSObject {
        public static var cache: [String: AccountItem] = [:]
        var Nonce: Int64?
        var Addr: String?
        var NickName: String?
        var Avatar: Data?
        var Balance: Int64?
        var TouchTime: Int64?
        var Owner: String?
        
        public static let shared = AccountItem()
        
        public override init() {
                super.init()
        }
        
        public static func initByOnlineMeta(_ obj: Data) -> AccountItem? {
                guard let objJson = try? JSON(data: obj) else{
                        print("------>>account details:=> failed to convert raw data to json object")
                        return nil
                }
                
                let data = AccountItem()
                data.Addr = objJson["addr"].string
                data.Nonce = objJson["nonce"].int64
                data.NickName = objJson["name"].string
                let str = objJson["avatar"].string
                data.Avatar = ChatLibUnmarshalGoByte(str)
                data.Balance = objJson["balance"].int64
                data.TouchTime = objJson["touch_time"].int64
                return data
                
        }
        
        public static func initByJson(_ account: JSON) -> AccountItem {
                let acc = AccountItem()
                acc.Nonce = account["nonce"].int64
                acc.Addr = account["addr"].string
                acc.NickName = account["name"].string
                acc.Balance = account["balance"].int64
                acc.TouchTime = account["touch_time"].int64
                acc.Owner = Wallet.shared.Addr!
                acc.Avatar = ChatLibAccountAvatar(acc.Addr, nil)
                return acc
        }
        
        public static func GetAccount(_ uid: String) -> AccountItem? {//TODO:: remove this usage
                var obj: AccountItem?
                obj = try? CDManager.shared.GetOne(entity: "CDAccount",
                                                   predicate: NSPredicate(format: "addr == %@", uid))
                return obj
        }
        
        public static func UpdateOrAddAccount(_ item: AccountItem) -> NJError? {
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDAccount",
                                                            m: item,
                                                            predicate: NSPredicate(format: "addr == %@", item.Addr!))
                } catch let err {
                        print("------>> account details: update local database by class object failed")
                        return NJError.account(err.localizedDescription)
                }
                return nil
        }
        
        public static func load(pid:String)->AccountItem?{
                var obj: AccountItem?
                obj = try? CDManager.shared.GetOne(entity: "CDAccount",
                                                   predicate: NSPredicate(format: "addr == %@", pid))
                if let item = obj{
                        return item
                }
                var error: NSError?
                
                if let data = ChatLibAccountDetail(pid, &error), error == nil {
                        guard let newItem = AccountItem.initByOnlineMeta(data) else{
                                return nil
                        }
                        
                        _ = UpdateOrAddAccount(newItem)
                        return newItem
                }
                
                return nil
        }
        
        public static func loadAccountDetailFromChain(addr: String) -> AccountItem? {
                var error: NSError?
                
                if let data = ChatLibAccountDetail(addr, &error), error == nil {
                        guard let newItem = AccountItem.initByOnlineMeta(data) else{
                                return nil
                        }
                        
                        _ = UpdateOrAddAccount(newItem)
                        return newItem
                }
                print("------>> load account detail from chain err:\(error!.localizedDescription)")
                return nil
        }
}

extension AccountItem: ModelObj {
        func fullFillObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDAccount else {
                        throw NJError.coreData("Cast to CDAccount failed")
                }
                cObj.name = self.NickName
                cObj.addr = self.Addr
                cObj.avatar = self.Avatar
                cObj.balance = self.Balance ?? 0
                
                cObj.nonce = self.Nonce ?? 0
                cObj.touch_time = self.TouchTime ?? 0
        }
        
        func initByObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDAccount else {
                        throw NJError.coreData("Cast to CDAccount failed")
                }
                self.TouchTime = cObj.touch_time
                self.Nonce = cObj.nonce
                self.Balance = cObj.balance
                self.Avatar = cObj.avatar
                self.Addr = cObj.addr
                self.NickName = cObj.name
        }
        
        
}
