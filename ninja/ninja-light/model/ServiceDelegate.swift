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
        public static let networkID = Int8(6)
        
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
                        print("----[Current Version]---\(current ?? "no current")----[Saved Version]---\(saved ?? "no saved")")
                        
                        //Tips::
                        let userDefault = UserDefaults.standard
                        userDefault.set(current, forKey: AppVersionKey)
                }
                // networkID 5: company 2: other
                
                ChatLibInitAPP("192.168.0.104", "a3a5c09826a246d0bfbef8084b81df1f", WebsocketSrv.shared, networkID)
        }
        public static func InitPushParam(deviceToken:String) {
                ChatLibSetPushParam(deviceToken, DevTypeIOS)
        }
        
        public static func MaxAvatarSize()->Int{
                return ChatLibMaxAvatarSize()
        }
        
        public static func MakeVideoSumMsg(rawData:Data)->(String?){
                var err:NSError?
                let has = ChatLibPostBigMsg(rawData, &err)
                if let e = err{
                        print("------>>>post big vedio failed:\(e.localizedDescription)")
                        return nil
                }
                _ = FileManager.writeByHash(has: has, content: rawData)
                return has
        }
        
        public static func MakeImgSumMsg(origin:Data, snapShotSize:Int)->(Data?, String?){
                let maxImgSize = ChatLibMaxFileSize()
                var rawData:Data = origin
                if origin.count > maxImgSize{
                        guard let rd = CompressImg(origin: origin, targetSize: maxImgSize) else{
                                print("------>>>compress too big imgage failed")
                                return (nil, nil)
                        }
                        rawData = rd
                }
                
                guard let snapShot = CompressImg(origin: rawData, targetSize: snapShotSize) else{
                        print("------>>>create snapshot failed")
                        return (nil, nil)
                }
                
                var err:NSError?
                let has = ChatLibPostBigMsg(rawData, &err)
                if let e = err{
                        print("------>>>post big image failed:\(e.localizedDescription )")
                        return (nil, nil)
                }
                
                _ = FileManager.writeByHash(has: has, content: rawData)
                return (snapShot, has)
        }
        
        public static func LoadDataByHash(has:String) -> Data?{
                if let d = FileManager.readByHash(has: has){
                        return d
                }
                var err:NSError?
                guard let d = ChatLibReadBigMsgByHash(has, &err) else{
                        return nil
                }
                
                _ = FileManager.writeByHash(has: has, content: d)
                return d
        }
        
        public static func getVideoUrlByHash(has:String)->URL?{
                if let url = FileManager.urlOfHash(has: has){
                        return url
                }
                
                var err:NSError?
                guard let d = ChatLibReadBigMsgByHash(has, &err) else{
                        return nil
                }
                
                return FileManager.writeByHash(has: has, content: d)
        }
        
        public static func CompressImg(origin:Data, targetSize:Int)->Data?{
                var err:NSError?
                guard let newData = ChatLibCompressImg(origin, Int32(targetSize), &err) else{
                        print("------>>>compress image failed:\(err?.localizedDescription ?? "<->")")
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
                GroupItem.loadCachedFromDB()
                MessageItem.prepareMessage()
                ChatItem.ReloadChatRoom()//TODO:: update chat item by new loaded message item queue
                
                dateFormatterGet.timeStyle = .medium
                WebsocketSrv.shared.Online()
        }
        
        public static func cleanAllMemoryCache() {
                CombineConntact.deleteAll()
                ChatItem.deleteAll()
                MessageItem.deleteAll()
                GroupItem.deleteAll()
        }
        
        
        public static func SyncChainData(data:Data){
                workQueue.async {
                        if let wallet = Wallet.initByData(data){
                                let err = Wallet.shared.UpdateWallet(w: wallet)
                                if err != nil{
                                        print("------>>>compress image failed:\(err?.localizedDescription ?? "<->")")
                                }
                        }
                        
                        _ = GroupItem.updatePartialGroup()      //TODO::have a full test
                        CombineConntact.updatePatialContacts()
                }
        }
        
        
        public static func ImportNewAccount(wJson:String, addr:String, pwd:String, parent:UIViewController, callback:(()->Void)?){
                
                parent.showSyncIndicator(withTitle: "Waiting".locStr, and: "Importing account".locStr)
                workQueue.async {
                        
                        WebsocketSrv.shared.Offline()
                        
                        if let err = Wallet.shared.Import(cipher: wJson, addr: addr, auth: pwd){
                                parent.toastMessage(title: "\(err.localizedDescription)")
                                parent.hideIndicator()
                                return
                        }
                        
                        print("------>>>new wallet \(String(describing: Wallet.shared.Addr))")
                        ServiceDelegate.cleanAllMemoryCache()
                        CombineConntact.SyncAllContactDataAtOnce()
                        GroupItem.SyncAllGroupDataFromChainAtOnce()
                        CDManager.shared.saveContext()
                        WebsocketSrv.shared.Online()
                        
                        parent.hideIndicator()
                        guard let cb = callback else{
                                return
                        }
                        cb()
                }
        }
        
        public static func queryNickAndAvatar(pid:String, callback:((_ name:String?, _ avatar:Data?)->Void)? = nil) ->(String?, Data?){
                if let acc = CombineConntact.cache[pid]{
                        return (acc.GetNickName(), acc.account?.Avatar)
                }
                if let acc = AccountItem.extraLoad(pid: pid){
                        return (acc.NickName, acc.Avatar)
                }
                
                ServiceDelegate.workQueue.async {
                        guard let acc = AccountItem.extraLoad(pid: pid, forceUpdate: true) else{
                                return
                        }
                        
                        guard let cb = callback else{
                                return
                        }
                        
                        cb(acc.NickName, acc.Avatar)
                }
                
                return (nil, nil)
        }
        
        public static func updateGroupInBackGround(group:GroupItem){
                workQueue.async {
                        ChatLibGroupNonce(group.gid, group.nonce)
                }
        }
        
        private static var groupAvatarTask:[String:Bool] = [:]
        private static let groupAvatarTaskLock:NSLock = NSLock()
        
        public static func InitGorupAvatar(group:GroupItem){
                if group.memberIds.count < 3{
                        print("------>>> invalid group number:=>", group.memberIds.count)
                        return
                }
                groupAvatarTaskLock.lock()
                if groupAvatarTask[group.gid] == true{
                        groupAvatarTaskLock.unlock()
                        return
                }
                groupAvatarTask[group.gid] = true
                groupAvatarTaskLock.unlock()
                
                workQueue.async {
                        var avatarArr:[Data]=[]
                        var imgData:Data?
                        var counter = 0
                        
                        for memID in group.memberIds {
                                if memID == Wallet.shared.Addr!{
                                        imgData = Wallet.shared.avatarData ?? defaultAvatarData
                                }
                                if let acc = CombineConntact.cache[memID]{
                                        imgData = acc.account?.Avatar
                                }
                                if let acc = AccountItem.extraLoad(pid: memID){
                                        imgData = acc.Avatar
                                }
                                guard let data = imgData else{
                                        continue
                                }
                                
                                counter += 1
                                avatarArr.append(data)
                                if counter >= 9{
                                        break
                                }
                        }
                        
                        for data in avatarArr {
                                ChatLibAddImg(data)
                        }
                        
                        var maxSup = group.memberIds.count
                        if maxSup > 9{
                                maxSup = 9
                        }
                        
                        maxSup = maxSup - counter
                        for _ in 0..<maxSup{
                                ChatLibAddImg(defaultAvatarData)
                        }
                        var err: NSError?
                        var groupAvatar = ChatLibCommitImg(&err)
                        if let e = err{
                                print("------>>> create group avatar failed:=>", e.localizedDescription)
                                groupAvatar = defaultAvatarData
                        }
                        
                        if let err = group.UpdateAvatarData(by: groupAvatar ?? defaultAvatarData){
                                print("------>>> UpdateAvatarData failed:=>", err.localizedDescription ?? "<->")
                        }
                        
                        groupAvatarTaskLock.lock()
                        groupAvatarTask.removeValue(forKey: group.gid)
                        groupAvatarTaskLock.unlock()
                }
        }
}
