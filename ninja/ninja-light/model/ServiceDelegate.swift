//
//  ServiceDelegate.swift
//  ninja-light
//
//  Created by wesley on 2021/4/6.
//

import Foundation
import ChatLib
import UIKit

class ServiceDelegate: NSObject {
        
        public static let workQueue = DispatchQueue.init(label: "Serivce Queue", qos: .utility)
        public static let DevTypeIOS = 1
        public static let Debug = true
            
        public static func getAgentStatus() -> AgentStatus {

                let balance = Wallet.shared.getBalance()

                if balance <= 0 {
                        return .initial
                }

                if balance < 5 {
                        return .almostExpire
                }

                return .activated
        }
        
        public static func InitAPP() {
                
                let endPoint = ConfigItem.loadEndPoint() ?? ""
                let current = getAppVersion()
                let saved = getSavedAppVersion()
                
                if current != saved {
                        NSLog("----[Current Version]---\(current ?? "no current")----[Saved Version]---\(saved ?? "no saved")")
                        
                        //Tips::
                        let userDefault = UserDefaults.standard
                        userDefault.set(current, forKey: AppVersionKey)
                }
                // networkID 5: company 2: other
                ChatLibInitAPP(endPoint, "a3a5c09826a246d0bfbef8084b81df1f", WebsocketSrv.shared, 2)
        }
        public static func InitPushParam(deviceToken:String) {
                ChatLibSetPushParam(deviceToken, DevTypeIOS)
        }
        
        public static func MaxAvatarSize()->Int{
                return ChatLibMaxAvatarSize()
        }
        
        public static func CompressImg(origin:Data, targetSize:Int)->Data?{
                var err:NSError?
                guard let newData = ChatLibCompressImg(origin, targetSize, &err) else{
                        NSLog("------>>>compress image failed:\(err?.localizedDescription ?? "<->")")
                        return nil
                }
                return newData
        }
        
        public static func transferLicense(to addr: String, days: Int) -> NSError? {
                var err:NSError?
                ChatLibTransferLicense(addr, days, &err)
                return err
        }
}

extension ServiceDelegate{
        
        public static func InitService() {
                CombineConntact.ReloadSavedContact()
                GroupItem.LocalSavedGroup()
                MessageItem.loadUnread()
                ChatItem.ReloadChatRoom()//TODO:: update chat item by new loaded message item queue
                
                dateFormatterGet.timeStyle = .medium
        }
        
        public static func cleanAllData() {
                CombineConntact.cache.removeAll()
                ChatItem.CachedChats.deleteAll()
                MessageItem.cache.deleteAll()
                GroupItem.cache.removeAll()
        }

        
        public static func SyncChainData(data:Data){
                workQueue.async {
                        
                        if let wallet = Wallet.initByData(data){
                               let err = Wallet.shared.UpdateWallet(w: wallet)
                                if err != nil{
                                        NSLog("------>>>compress image failed:\(err?.localizedDescription ?? "<->")")
                                }
                        }
                        
                        _ = GroupItem.updatePartialGroup()
                        CombineConntact.updatePatialContacts()
                }
        }
        
        
        public static func ImportNewAccount(wJson:String, addr:String, pwd:String, parent:UIViewController, callback:(()->Void)?){
                
                parent.showSyncIndicator(withTitle: "waiting", and: "importing account")
                workQueue.async {
                        
                        WebsocketSrv.shared.Offline()
                        
                        if let err = Wallet.shared.Import(cipher: wJson, addr: addr, auth: pwd){
                                parent.toastMessage(title: err.localizedDescription)
                                parent.hideIndicator()
                                return
                        }
                        
                        NSLog("------>>>new wallet \(String(describing: Wallet.shared.Addr))")
                        ServiceDelegate.cleanAllData()
                        
                        if let err = GroupItem.syncAllGroupDataAtOnce(){
                                NSLog("------>>> sync group metas when import account:", err.localizedDescription)
                        }
                        
                        CombineConntact.syncAllContactDataAtOnce()
                        
                        parent.hideIndicator()
                        guard let cb = callback else{
                                return
                        }
                        cb()
                }
        }
}
