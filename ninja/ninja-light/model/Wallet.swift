//
//  Wallet.swift
//  ninja-light
//
//  Created by wesley on 2021/4/5.
//

import Foundation
import CoreData
import ChatLib
//import SwiftyJSON

class Wallet: NSObject{
        var obj: CDWallet?
        var Addr: String?
        var wJson: String?
        var nickName: String?
        var useFaceID = false
        var useDestroy = false
        var liceneseExpireTime: Int64 = 0

        public static let shared = Wallet()

        lazy var loaded: Bool = {
        do {
            var inst:Wallet?
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
    
        func Copy(_ a: Wallet) {
                self.Addr = a.Addr
                self.wJson = a.wJson
                self.obj = a.obj
                self.nickName = a.nickName
                self.useFaceID = a.useFaceID
                self.useDestroy = a.useDestroy
                self.liceneseExpireTime = a.liceneseExpireTime
        }
    
        func New(_ password: String) throws {
                let walletJson =  ChatLibNewWallet(password)
                if walletJson == ""{
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
                try CDManager.shared.Delete(entity: "CDWallet")
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

        func Import(cipher walletJson: String, addr: String, auth password: String) throws {

                self.Addr = addr
                self.wJson = walletJson
                self.loaded = true
                self.useFaceID = false
                self.useDestroy = false
                self.nickName = ""

                ServiceDelegate.InitService()
                if let err = Active(password) {
                        print("Import Failed\(String(describing: err.localizedDescription))")
                }

                try CDManager.shared.Delete(entity: "CDWallet")
                try CDManager.shared.UpdateOrAddOne(entity: "CDWallet", m: self)

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
        }
    
}
