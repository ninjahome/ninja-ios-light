//
//  Wallet.swift
//  ninja-light
//
//  Created by wesley on 2021/4/5.
//

import Foundation
import CoreData
import ChatLib
import SwiftyJSON

class Wallet: NSObject {
        var obj: CDWallet?
        var Addr: String?
        var wJson: String?
        var nickName: String?
        var useFaceID = false
        var useDestroy = false
        var liceneseExpireTime: Int64 = 0
        var avatarData: Data?
        var touchTime: Int64?
        var nonce: Int64?
        
        public static let shared = Wallet()
        
        lazy var loaded: Bool = {
                do {
                        var inst: Wallet?
                        inst = try CDManager.shared.GetOne(entity: "CDWallet",
                                                           predicate: nil)
                        if inst == nil {
                                return false
                        }
                        self.Copy(inst!)
                } catch {
                        return false
                }
                
                return self.obj != nil
        }()
        
        public static func initByData(_ obj: Data) -> Wallet? {
                guard let objJson = try? JSON(data: obj)  else{
                        return nil
                }
                let data = Wallet()
                data.Addr = objJson["addr"].string
                data.nonce = objJson["nonce"].int64
                data.nickName = objJson["name"].string
                
                if let str = objJson["avatar"].string, !str.isEmpty{
                        data.avatarData = ChatLibUnmarshalGoByte(str)
                }else{
                        var err:NSError?
                        data.avatarData = ChatLibAccountAvatar(data.Addr, &err)
                        if err != nil{
                                NSLog("------>no avatar data on chain")
                        }
                }
                
                data.liceneseExpireTime = objJson["balance"].int64 ?? 0
                data.touchTime = objJson["touch_time"].int64
                return data
        }
        
        public func isStillVip() -> Bool {
                return Int64(Date().timeIntervalSince1970) < self.liceneseExpireTime
        }
        
        func getLatestWallt() {
                var error: NSError?
                guard let data = ChatLibAccountDetail(self.Addr!, &error) else {
                        NSLog("-----[getLatestWallt]------>:\(error?.localizedDescription ?? "no error")")
                        return
                }
                if let item = Wallet.initByData(data) {
                        _ = self.UpdateWallet(w: item)
                }
        }
        
        func getWalletFromETH() {
                var error: NSError?
                guard let data = ChatLibAccountBalance(self.Addr!, &error) else {
                        NSLog("------[getWalletFromETH]----->:\(error?.localizedDescription ?? "no error")")
                        return
                }
                if let item = Wallet.initByData(data) {
                        _ = self.UpdateWallet(w: item)
                }
        }
        
        func accountNonce() {
                ChatLibAccountNonce(self.nonce ?? 0)
        }
        
        func Copy(_ a: Wallet) {
                self.Addr = a.Addr
                self.wJson = a.wJson
                self.obj = a.obj
                self.nonce = a.nonce
                self.nickName = a.nickName
                self.useFaceID = a.useFaceID
                self.useDestroy = a.useDestroy
                self.liceneseExpireTime = a.liceneseExpireTime
                self.avatarData = a.avatarData
        }
        
        func Update(_ a: Wallet) {
                self.nickName = a.nickName
                self.liceneseExpireTime = a.liceneseExpireTime
                self.avatarData = a.avatarData
                self.nonce = a.nonce
                self.touchTime = a.touchTime
        }
        
        func New(_ password: String) throws {
                let walletJson =  ChatLibNewWallet(password)
                if walletJson == "" {
                        throw NJError.wallet("Create Wallet Failed")
                }
                
                let addr = ChatLibWalletAddress()
                if addr == ""{
                        throw NJError.wallet("Create Wallet Failed")
                }
                self.Addr = addr
                self.wJson = walletJson
                self.loaded = true
                self.useFaceID = false
                self.useDestroy = false
                self.nickName = ""
                self.liceneseExpireTime = 0
                
                try CDManager.shared.AddEntity(entity: "CDWallet", m: self)
        }
        
        func IsActive() -> Bool {
                return ChatLibWalletIsOpen()
        }
        
        func Active(_ password: String) -> Error? {
                var error:NSError? = nil
                ChatLibActiveWallet(self.wJson, password, &error)
                return error
        }
        
        func serializeWalletJson(cipher walletJson: String) -> String? {
                let walletData = walletJson.data(using: .utf8)!
                let json = try? JSONSerialization.jsonObject(with: walletData, options: .mutableContainers) as? [String: Any]
                
                let addr = json?["address"] as? String
                
                return addr
        }
        
        func Import(cipher walletJson: String, addr: String, auth password: String)  -> Error?{
                self.Addr = addr
                self.wJson = walletJson
                self.loaded = true
                self.useFaceID = false
                self.useDestroy = false
                self.nickName = ""
                self.nonce = 0
                
                if let err = Active(password) {
                        NSLog("------>>>Import Failed\(String(describing: err.localizedDescription))")
                        return err
                }
                
                var error: NSError?
                guard let data = ChatLibAccountDetail(addr, &error) else{
                        return error
                }
                
                guard let item = Wallet.initByData(data) else{
                        return NJError.wallet("------>>> invalid account meta from chain ")
                }
                Update(item)
                do{
                        try CDManager.shared.Delete(entity: "CDWallet")
                        try CDManager.shared.UpdateOrAddOne(entity: "CDWallet", m: self)
                        
                }catch let err{
                        return err
                }
                return nil
        }
        
        func UpdateWallet(w: Wallet) -> NJError? {
                Update(w)
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDWallet", m: self, predicate: NSPredicate(format: "address == %@ AND jsonStr == %@", self.Addr!, self.wJson!))
                } catch let err {
                        return NJError.wallet(err.localizedDescription)
                }
                return nil
        }
        
        func UpdateNick(by nick: String) -> NJError? {
                self.nickName = nick
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDWallet", m: self, predicate: NSPredicate(format: "address == %@ AND jsonStr == %@", self.Addr!, self.wJson!))
                } catch let err {
                        return NJError.wallet(err.localizedDescription)
                }
                return nil
        }
        
        func openDestroy(auth: String) -> Bool {
                if DeriveAesKey() == auth {
                        return false
                }
                
                SetDestroyKey(auth: auth)
                if UpdateUseDestroy(by: true) != nil {
                        return false
                }
                
                return true
        }
        
        func UpdateUseDestroy(by use: Bool) -> NJError? {
                self.useDestroy = use
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDWallet", m: self, predicate: NSPredicate(format: "address == %@ AND jsonStr == %@", self.Addr!, self.wJson!))
                } catch let err {
                        return NJError.wallet(err.localizedDescription)
                }
                return nil
        }
        
        func UpdateUseFaceID(by use: Bool) -> NJError? {
                self.useFaceID = use
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDWallet",
                                                            m: self,
                                                            predicate: NSPredicate(format: "address == %@ AND jsonStr == %@", self.Addr!, self.wJson!))
                } catch let err {
                        return NJError.wallet(err.localizedDescription)
                }
                return nil
        }
        
        func UpdateLicense(by new: Int64) -> NJError? {
                self.liceneseExpireTime = new
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDWallet",
                                                            m: self,
                                                            predicate: NSPredicate(format: "address == %@ AND jsonStr == %@", self.Addr!, self.wJson!))
                } catch let err {
                        return NJError.wallet(err.localizedDescription)
                }
                return nil
        }
        
        func UpdateAvatarData(by data: Data) -> NJError? {
                self.avatarData = compressImage(data)
                var error: NSError?
                if ChatLibUpdateAvatar(data, &error), error == nil {
                        do {
                                try CDManager.shared.UpdateOrAddOne(entity: "CDWallet",
                                                                    m: self,
                                                                    predicate: NSPredicate(format: "address == %@ AND jsonStr == %@", self.Addr!, self.wJson!))
                        } catch let err {
                                return NJError.wallet(err.localizedDescription)
                        }
                        return nil
                }
                return NJError.wallet(error?.localizedDescription ?? "update avatar in chain faild")
        }
        
        func openFaceID(auth: String) -> Bool {
                guard let _ = Active(auth) else {
                        SetAesKey(auth: auth)
                        if UpdateUseFaceID(by: true) != nil {
                                return false
                        }
                        return true
                }
                return false
        }
        
        func IsValidWalletJson(_ walletJson: String) -> Bool {
                guard let qrData: Data = ((walletJson).data(using: .utf8)) else {
                        return false
                }
                let json = try? JSONSerialization.jsonObject(with: qrData, options: .mutableContainers) as? [String: Any]
                
                if json?["address"] != nil {
                        return true
                }
                return false
        }
        
        static func GenAvatarColor() -> String {
                guard let addr = Wallet.shared.Addr else {
                        return AvatarColors[12]
                }
                let idx = ChatLibIconIndex(addr, 12)
                return AvatarColors[Int(idx)]
        }
        
        static func GenAvatarText() -> String {
                let addr = Wallet.shared.Addr!
                guard let nick = Wallet.shared.nickName, nick != "" else {
                        return String(addr.prefix(2))
                }
                return String(nick.prefix(2))
        }
        
}

extension Wallet: ModelObj {
        
        func fullFillObj(obj: NSManagedObject) throws {
                guard let wObj = obj as? CDWallet else {
                        throw NJError.coreData("Cast to CDWallet failed")
                }
                wObj.address = self.Addr
                wObj.jsonStr = self.wJson
                wObj.nick = self.nickName
                wObj.useFaceID = self.useFaceID
                wObj.useDestroy = self.useDestroy
                wObj.liceneseExpireTime = self.liceneseExpireTime
                wObj.avatar = self.avatarData
                wObj.nonce = self.nonce ?? 0
                self.obj = wObj
        }
        
        func initByObj(obj: NSManagedObject) throws {
                guard let wObj = obj as? CDWallet else {
                        throw NJError.coreData("Cast to CDWallet failed")
                }
                self.obj = wObj
                self.Addr = wObj.address
                self.wJson = wObj.jsonStr
                self.nickName = wObj.nick
                self.useFaceID = wObj.useFaceID
                self.useDestroy = wObj.useDestroy
                self.liceneseExpireTime = wObj.liceneseExpireTime
                self.avatarData = wObj.avatar
                self.nonce = wObj.nonce
        }
        
}
