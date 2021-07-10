//
//  Wallet.swift
//  ninja-light
//
//  Created by wesley on 2021/4/5.
//

import Foundation
import CoreData
import IosLib
import SwiftyJSON

class Wallet:NSObject{
        var obj:CDWallet?
        var Addr:String?
        var wJson:String?
        var nickName:String?
        var useFaceID = false
        var deviceToken:String?
    
        public static let shared = Wallet()
        private override init() {
                super.init()
        }
        
        lazy var loaded: Bool = {
                do {
                        var inst:Wallet?
                        inst = try CDManager.shared.GetOne(entity: "CDWallet", predicate: nil)
                        if inst == nil{
                                return false
                        }
                        
                        self.Copy(inst!)
                } catch{
                        return false
                }
                
                return self.obj != nil
        }()
        
        func Copy(_ a:Wallet){
                self.Addr = a.Addr
                self.wJson = a.wJson
                self.obj = a.obj
                self.nickName = a.nickName
                self.useFaceID = a.useFaceID
        }
        
        func New(_ password:String) throws {
                let walletJson =  IosLib.IosLibNewWallet(password)
                if walletJson == ""{
                        throw NJError.wallet("Create Wallet Failed")
                }
                let addr = IosLib.IosLibActiveAddress()
                if addr == ""{
                        throw NJError.wallet("Create Wallet Failed")
                }
                self.Addr = addr
                self.wJson = walletJson
                self.loaded = true
                self.useFaceID = false
                self.nickName = ""
                try CDManager.shared.Delete(entity: "CDWallet")
                try CDManager.shared.AddEntity(entity: "CDWallet", m: self)
        }
    
        func IsActive()->Bool{
                return IosLib.IosLibWalletIsOpen()
        }
            
        func Active(_ password:String)-> Error? {
                var error:NSError? = nil
//                IosLib.IosLibActiveWallet(self.wJson, password, &error)
                IosLib.IosLibActiveWallet(self.wJson, password, self.deviceToken, &error)
                return error
        }
    
        func serializeWalletJson(cipher walletJson: String) -> String? {
                let walletData = walletJson.data(using: .utf8)!
                let json = try? JSONSerialization.jsonObject(with: walletData, options: .mutableContainers) as? [String: Any]
                
                let addr = json?["address"] as? String
                
                return addr
        }
    
        func Import(cipher walletJson: String, addr: String, auth password: String) throws {
                var error: NSError? = nil
//                IosLib.IosLibActiveWallet(walletJson, password, &error)
                IosLib.IosLibActiveWallet(walletJson, password, self.deviceToken, &error)
                if error != nil {
                    print("Import Failed\(String(describing: error?.localizedDescription))")
                }
                print("Import address \(addr)")
                if addr != "" {
                    self.Addr = addr
                    self.wJson = walletJson
                    self.nickName = ""
                    self.loaded = true
                    self.useFaceID = false
    //                try CDManager.shared.AddEntity(entity: "CDWallet", m: self)
                    try CDManager.shared.Delete(entity: "CDWallet")
                    try CDManager.shared.UpdateOrAddOne(entity: "CDWallet", m: self)

                } else {
                    throw NJError.wallet("Import Wallet Init Failed")
                }
            
        }
    
        func setDeviceToken(_ token: String) {
            self.deviceToken = token
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
    
        func UpdateUseFaceID(by use: Bool) -> NJError? {
                self.useFaceID = use
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDWallet", m: self, predicate: NSPredicate(format: "address == %@ AND jsonStr == %@", self.Addr!, self.wJson!))
                } catch let err {
                        return NJError.wallet(err.localizedDescription)
                }
                return nil
        }
    
        func openFaceID(auth: String) -> Bool {
            guard let _ = Active(auth) else {
                DeriveAesKey(auth: auth)
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
            let json = JSON(qrData)
            
            if json["address"].exists() {
                return true
            }
            return false
        }
    
        static func GenAvatarColor() -> String {
            guard let addr = Wallet.shared.Addr else {
                return AvatarColors[12]
            }
            let idx = IosLib.IosLibIconIndex(addr, 12)
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

extension Wallet:ModelObj {
        
        func fullFillObj(obj: NSManagedObject) throws {
                guard let wObj = obj as? CDWallet else{
                        throw NJError.coreData("Cast to CDWallet failed")
                }
                wObj.address = self.Addr
                wObj.jsonStr = self.wJson
                wObj.nick = self.nickName
                wObj.useFaceID = self.useFaceID
                self.obj = wObj
        }
        
        func initByObj(obj: NSManagedObject) throws{
                guard let wObj = obj as? CDWallet else{
                        throw NJError.coreData("Cast to CDWallet failed")
                }
                self.obj = wObj
                self.Addr = wObj.address
                self.wJson = wObj.jsonStr
                self.nickName = wObj.nick
                self.useFaceID = wObj.useFaceID
        }
}
