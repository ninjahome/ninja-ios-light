//
//  Wallet.swift
//  ninja-light
//
//  Created by wesley on 2021/4/5.
//

import Foundation
import CoreData
import IosLib


class Wallet:NSObject{
        var obj:CDWallet?
        var Addr:String?
        var wJson:String?
        var nickName:String?
        
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
                try CDManager.shared.AddEntity(entity: "CDWallet", m: self)
        }
        func IsActive()->Bool{
                return IosLib.IosLibWalletIsOpen()
        }
        
        func Active(_ password:String)-> Error? {
                var error:NSError? = nil
                IosLib.IosLibActiveWallet(self.wJson, password, &error)
                return error
        }
    
        func Import(cipher walletJson: String, auth password: String) -> Error? {
                var error: NSError? = nil
                IosLib.IosLibActiveWallet(walletJson, password, &error)
                return error
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
    
}

extension Wallet:ModelObj{
        
        func fullFillObj(obj: NSManagedObject) throws {
                guard let wObj = obj as? CDWallet else{
                        throw NJError.coreData("Cast to CDWallet failed")
                }
                wObj.address = self.Addr
                wObj.jsonStr = self.wJson
                wObj.nick = self.nickName
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
        }
}
