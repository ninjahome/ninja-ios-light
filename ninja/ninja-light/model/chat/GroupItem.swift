//
//  GroupItem.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/8.
//

import Foundation
import CoreData
import ChatLib
import SwiftyJSON
import UIKit

struct memberInfo {
        var id: String
        var name: String = ""
        
        init(id: String, name: String) {
                self.id = id
                self.name = name
        }
}

class GroupItem: NSObject {
        
        public static var cache:[String:GroupItem]=[:]
        
        
        var nonce: Int64?
        var gid: String = ""
        var groupName: String?
        var memberIds: [String] = []
        var owner: String?
        var unixTime: Int64 = 0
        var leader: String?
        var isDelete: Bool = false
        var avatar: Data?
        
        var memberInfos: [String:String] = [:]
        
        override init() {
                super.init()
        }
        
        init(gid:String, name:String, members:[String]){
                super.init()
                let wallet = Wallet.shared.Addr!
                self.nonce = 0
                self.gid = gid
                self.groupName = name
                self.memberIds = members
                self.owner = wallet
                self.leader = wallet
                self.unixTime = Int64(Date().timeIntervalSince1970)
                self.isDelete = false
                
                if let avatarData = GroupItem.genGroupAvatar(ids:members){
                        avatar = avatarData
                }else{
                        avatar = defaultAvatar.jpegData(compressionQuality: 1)!
                }
        }
        
        public static func initByJson(json objJson:JSON) -> GroupItem?{
                guard let memIds = objJson["members"].dictionaryObject?.keys, memIds.count >= 2 else {
                        print("------>>> invalid group json data: too less members")
                        return nil
                }
                guard let gid = objJson["gid"].string else{
                        print("------>>> invalid group json data: no group id")
                        return nil
                }
                let grp = GroupItem()
                grp.gid = gid
                grp.nonce = objJson["nonce"].int64
                grp.leader = objJson["owner"].string
                grp.groupName = objJson["name"].string
                grp.isDelete = objJson["deleted"].bool ?? false
                
                var ids : [String] = []
                for k in memIds {
                        let uid = String(k)
                        ids.append(uid)
                }
                grp.memberIds = ids
                grp.owner = Wallet.shared.Addr!
                
                if AccountItem.GetAccount(grp.leader!) == nil {
                        _ = AccountItem.loadAccountDetailFromChain(addr: grp.leader!)
                }
                
                for i in grp.memberIds {
                        if AccountItem.GetAccount(i) == nil {
                                _ = AccountItem.loadAccountDetailFromChain(addr: i )
                        }
                }
                
                if grp.avatar == nil{
                        var allIds = grp.memberIds
                        allIds.append(grp.leader!)
                        if let grpImg = GroupItem.genGroupAvatar(ids: allIds) {
                                grp.avatar = grpImg
                        }
                }
                
                return grp
        }
        
        public static func loadCachedFromDB() {
                guard let owner = Wallet.shared.Addr else {
                        return
                }
                do{
                        var result: [GroupItem] = []
                        result = try CDManager.shared.Get(entity: "CDGroup",
                                                          predicate: NSPredicate(format: "owner == %@", owner),
                                                          sort: [["name" : true]])
                        if result.count == 0{
                                print("------>>>no group at all")
                                return
                        }
                        
                        for obj in result {
                                cache[obj.gid] = obj
                                print("------>>>saved group\(obj.groupName ?? obj.gid) loaded")
                        }
                        
                }catch let err{
                        print("------>>>loading cached group meta failed =>", err.localizedDescription)
                }
        }
        
        public static func CacheArray() -> [GroupItem] {
                return Array(cache.values)
        }
        
        public static func genGroupAvatar(ids: [String]) -> Data? {
                let defaultAvatarData = defaultAvatar.jpegData(compressionQuality: 1)!
                var counter = 0
                var imgData:Data?// = defaultAvatarData
                for id in ids{
                        if counter >= 9{
                                break
                        }
                        if id == Wallet.shared.Addr{
                                imgData = Wallet.shared.avatarData
                        }else{
                                (_, imgData) = ServiceDelegate.queryNickAndAvatar(pid: id)
                        }
                        if imgData == nil{
                                imgData = defaultAvatarData
                        }
                        counter += 1
                        ChatLibAddImg(imgData)
                }
                var err: NSError?
                if let avatar = ChatLibCommitImg(&err) {
                        return avatar
                }
                print("---[group image]--->>>\(err?.localizedDescription ?? "")")
                return nil
        }
}

//MARK: - private  operation
extension GroupItem {
        
        
        private static func GetGroupFromDbBy(_ gid: String) -> GroupItem? {
                
                let owner = Wallet.shared.Addr!
                var obj: GroupItem?
                obj = try? CDManager.shared.GetOne(entity: "CDGroup",
                                                   predicate: NSPredicate(format: "gid == %@ AND owner == %@", gid, owner))
                guard let item = obj else{
                        cache.removeValue(forKey: gid)
                        return nil
                }
                cache[gid] = item
                cache.updateValue(item, forKey: gid)
                return item
        }
        
        private static func syncGroupToDB(_ group: GroupItem)throws{
                
                group.owner = Wallet.shared.Addr
                try CDManager.shared.UpdateOrAddOne(entity: "CDGroup",
                                                    m: group,
                                                    predicate: NSPredicate(format: "gid == %@ AND owner == %@",
                                                                           group.gid, group.owner!))
                
                cache[group.gid] = group
                cache.updateValue(group, forKey: group.gid)
        }
        
        private static func deleteGroupFromDB(_ gid: String) -> NJError? {
                let owner = Wallet.shared.Addr!
                do {
                        try CDManager.shared.Delete(entity: "CDGroup", predicate: NSPredicate(format: "gid == %@ AND owner == %@", gid, owner))
                        
                        cache.removeValue(forKey: gid)
                } catch let err {
                        return NJError.group(err.localizedDescription)
                }
                return nil
        }
        
        private static func syncGroupMetaFromChainBy(groupID: String) -> GroupItem? {
                var err: NSError?
                
                guard let data = ChatLibGroupMeta(groupID, &err) else {
                        return nil
                }
                guard let objJson = try? JSON(data: data) else{
                        return nil
                }
                guard let group = GroupItem.initByJson(json: objJson) else {
                        return nil
                }
                
                do  {
                        try syncGroupToDB(group)
                        
                } catch let err{
                        print("---[update grp]---?\(err.localizedDescription )")
                }
                
                return group
        }
}
//MARK: - core data operation
extension GroupItem: ModelObj {
        
        func fullFillObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDGroup else {
                        throw NJError.coreData("Cast to CDGroup failed")
                }
                //                self.UpdateSelfInfos()
                cObj.gid = self.gid
                cObj.name = self.groupName
                cObj.owner = self.owner
                cObj.members = self.memberIds as NSObject
                //                cObj.memberNicks = self.memberNicks
                cObj.unixTime = self.unixTime
                cObj.leader = self.leader
                cObj.isDelete = self.isDelete
                cObj.avatar = self.avatar
                
        }
        
        func initByObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDGroup else {
                        throw NJError.coreData("Cast to CDGroup failed")
                }
                
                self.gid = cObj.gid ?? "<->"
                self.groupName = cObj.name
                self.owner = cObj.owner
                self.memberIds = cObj.members as? [String] ?? []
                self.unixTime = cObj.unixTime
                self.leader = cObj.leader
                self.avatar = cObj.avatar
                self.isDelete = cObj.isDelete
        }
}
//MARK: - basic group operation
extension GroupItem{
        
        public static func NewGroup(ids: [String], groupName: String?)throws -> GroupItem{
                
                var memIDs:[String] = []
                memIDs.append(contentsOf: ids)
                
                let data = try JSON(memIDs).rawData()
                
                var err: NSError?
                let gid = ChatLibCreateGroup(groupName, data, &err)
                if let e = err{
                        throw e
                }
                var grpName = gid
                if let n = groupName, !n.isEmpty{
                        grpName = n
                }
                let leader = Wallet.shared.Addr!
                memIDs.append(leader)
                let item = GroupItem(gid:gid, name:grpName, members:memIDs)
                try syncGroupToDB(item)
                CDManager.shared.saveContext()
                return item
        }
        
        
        public static func DismissGroup(gid: String) -> NJError? {
                var error: NSError?
                _ = ChatLibDismissGroup(gid, &error)
                if error != nil {
                        return NJError.group(error!.localizedDescription)
                }
                
                _ = GroupItem.deleteGroupFromDB(gid)
                ChatItem.remove(gid)
                MessageItem.removeRead(gid)
                CDManager.shared.saveContext()
                
                return nil
        }
        
        public static func updateGroupName(group:GroupItem, newName:String)->Error?{
                
                var err: NSError?
                let hashTx = ChatLibChangeGroupName(group.gid, newName, &err)
                
                if let e = err{
                        return e
                }
                
                do{
                        group.groupName = newName
                        try syncGroupToDB(group)}catch let err{
                                return err
                        }
                CDManager.shared.saveContext()
                print("------>>>group name update hash:\(hashTx)")
                return nil
        }
        
        public static func syncAllGroupDataFromChainAtOnce(){
                
                var err: NSError?
                guard let data = ChatLibSyncGroupWithDetails(&err) else{
                        print("------>>> sync group metas when import account:", err?.localizedDescription ?? "<->")
                        return
                }
                guard let grpArr = try? JSON(data:data) else{
                        print("------>>>pasrse group array message failed")
                        return
                }
                
                for (index, groupJson):(String, JSON) in grpArr {
                        
                        guard let group = GroupItem.initByJson(json: groupJson) else{
                                print("------>>>[syncAllGroupDataAtOnce]failed parse group item[\(index)]")
                                continue
                        }
                        
                        do {try syncGroupToDB(group) }catch let err {
                                
                                print("---[update grp]---\(err.localizedDescription )")
                                continue
                        }
                        
                        GroupItem.cache[group.gid] = group
                }
        }
        
        public static func AddMemberToGroup(group: GroupItem, newIds: [String]) -> Error? {
                var error: NSError?
                let to = group.memberIds
                let idsData = ChatLibUnmarshalGoByte(to.toString())
                ChatLibAddGroupMembers(group.gid, idsData, &error)
                if let err = error{
                        return err
                }
                do {
                        try GroupItem.syncGroupToDB(group)
                        
                } catch let err{
                        return err
                }
                return nil
        }
        
        public static func KickOutUser(group: GroupItem, kickUserId: [String]) -> NJError? {
                
                try? GroupItem.syncGroupToDB(group)
                return nil
        }
        
        public static func KickOutUserNoti(group: GroupItem, kickIds: String?, from: String) throws {
                guard let kick = kickIds?.toArray() else {
                        return
                }
                
                if kick.contains(Wallet.shared.Addr!) {
                        let _ = GroupItem.deleteGroupFromDB(group.gid)
                        NotificationCenter.default.post(name: NotifyKickMeOutGroup,
                                                        object: group)
                        return
                }
                
                for k in kick {
                        group.memberInfos.removeValue(forKey: k as! String)
                }
                
                let newIds = group.memberInfos.map { (key: String, value: String) in
                        return key
                }
                
                group.memberIds = newIds
                
                try GroupItem.syncGroupToDB(group)
                
                let NotiKey_ids = "KICK_IDS"
                let NotiKey_from = "KICK_FROM"
                NotificationCenter.default.post(name: NotifyKickOutGroup,
                                                object: self,
                                                userInfo: [NotiKey_ids: kickIds!, NotiKey_from: from])
                
        }
        
        public static func QuitGroupNoti(from: String?, groupId: String, quitId: String) throws {
                if let group = GroupItem.GetGroupFromDbBy(groupId) {
                        group.memberInfos.removeValue(forKey: quitId)
                        
                        let newIds = group.memberInfos.map { (key: String, value: String) in
                                return key
                        }
                        
                        group.memberIds = newIds
                        try GroupItem.syncGroupToDB(group)
                }
                
        }
}

//MARK: - call from or to websocket
extension GroupItem{
        
        public static func getMembersOfGroup(gid: String) -> Data? {
                guard let grpItem = GroupItem.GetGroupFromDbBy(gid) else {
                        return nil
                }
                
                var ids: [String] = grpItem.memberIds
                ids.append(grpItem.leader!)
                
                let jsonStr = JSON(ids).description
                guard let data = jsonStr.data(using: .utf8) else {
                        return nil
                }
                
                return data
        }
        
        public static func updatePartialGroup() -> NSError?{
                var err: NSError?
                
                guard let data = ChatLibSyncGroupIDs(&err) else{
                        return err
                }
                guard let groups = try? JSON(data: data)["groups"] else{
                        return NJError.group("no groupship") as NSError
                }
                
                for (gid , _):(String, JSON) in groups {
                        
                        if let _ = GetGroupFromDbBy(gid){
                                continue
                        }
                        
                        let _ = syncGroupMetaFromChainBy(groupID: gid)
                }
                
                return nil
        }
        
        
        public static func GroupMeataNotified(data: Data){
                print("------>>>[groupUpdate] group data=>", String(data:data, encoding: .utf8))
        }
}
