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
        var Balance: String?
        var TouchTime: Int64?
        var Owner: String?
        
        public static let shared = AccountItem()
        
        public override init() {
                super.init()
        }
        
        public static func initByData(_ obj: Data) -> AccountItem? {
                if let objJson = try? JSON(data: obj) {
                        let data = AccountItem()
                        data.Addr = objJson["addr"].string
                        data.Nonce = objJson["nonce"].int64
                        data.NickName = objJson["name"].string
                        let str = objJson["avatar"].string
                        data.Avatar = ChatLibUnmarshalGoByte(str)
                        data.Balance = objJson["balance"].string
                        data.TouchTime = objJson["touch_time"].int64
                        return data
                }
                return nil
        }
        
        public static func initByJson(_ account: JSON) -> AccountItem {
                let acc = AccountItem()
                acc.Nonce = account["nonce"].int64
                acc.Addr = account["addr"].string
                acc.NickName = account["name"].string
                acc.Balance = account["balance"].string
                acc.TouchTime = account["touch_time"].int64
                acc.Owner = Wallet.shared.Addr!
                acc.Avatar = ChatLibAccountAvatar(acc.Addr, nil)
                return acc
        }
        
        public static func GetAccount(_ uid: String) -> AccountItem? {
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
                    return NJError.account(err.localizedDescription)
                }
                return nil
        }
        
        func getLatestAccount(addr: String) -> AccountItem? {
                var error: NSError?
                if let data = ChatLibAccountDetail(addr, &error), error == nil {
                        let item = AccountItem.initByData(data)
                        return item
                }
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
                cObj.balance = self.Balance
                
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
