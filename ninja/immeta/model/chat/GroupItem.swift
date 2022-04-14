//
//  GroupItem.swift
//  immeta
//
//  Created by ribencong on 2021/8/8.
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

//MARK: - basic init
class GroupItem: NSObject {
        public static let CDEntityName = "CDGroup"
        public static var cache:[String:GroupItem]=[:]
        
        var nonce: Int64=0
        var gid: String = ""
        var groupName: String?
        var memberIds: [String] = []
        var owner: String=Wallet.shared.Addr!
        var unixTime: Int64 = 0
        var leader: String = ""
        var isDelete: Bool = false
        var avatar: Data?
        
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
                self.avatar = nilAvatar
        }
        
        public func ToString() ->String{
                return """
                ------------------\(self.nonce)------------------"
                =id\t\(self.gid)=
                =name\t\(self.groupName ?? "<->")=
                =leader\t\(self.leader)=
                =isDelete\t\(self.isDelete)=
                =memberIds\t\(self.memberIds.toString() ?? "<->")=
                =unixTime\t\(self.unixTime)=
                =owner\t\(self.owner)=
                =avatar\t\(self.avatar?.count ?? 0)=
                --------------------------------------------------"
                """
        }
        
        public static func initByJson(json objJson:JSON) -> GroupItem?{
                guard let memIds = objJson["members"].dictionaryObject?.keys, memIds.count > 0 else {
                        print("------>>> invalid group json data: no members")
                        return nil
                }
                guard let gid = objJson["gid"].string else{
                        print("------>>> invalid group json data: no group id")
                        return nil
                }
                let grp = GroupItem()
                grp.gid = gid
                grp.nonce = objJson["nonce"].int64 ?? 0
                grp.leader = objJson["owner"].string!
                grp.groupName = objJson["name"].string
                grp.isDelete = objJson["deleted"].bool ?? false
                
                if let time = objJson["touch_time"].string {
                        grp.unixTime = GoTimeStringToSwiftDate(str: time)
                }
                
                var ids : [String] = [grp.leader]
                for k in memIds {
                        let uid = String(k)
                        ids.append(uid)
                }
                
                grp.memberIds = ids
                grp.owner = Wallet.shared.Addr!
                
                return grp
        }
        func UpdateAvatarData(by data:Data) ->NJError?{
                do{
                        try CDManager.shared.Update(entity: GroupItem.CDEntityName,
                                                    predicate: NSPredicate(format: "gid == %@", self.gid), update: { obj in
                                guard let group  = obj as? CDGroup else{
                                        return
                                }
                                group.avatar = data
                        })
                        self.avatar = data
                        GroupItem.cache.updateValue(self, forKey: self.gid)
                        CDManager.shared.saveContext()
                        NotificationCenter.default.post(name:NotifyGroupNameOrAvatarChanged,
                                                        object: self.gid,
                                                        userInfo:nil)
                        return nil
                }catch let err{
                        return NJError.group("save data base err:".locStr+"[\(err.localizedDescription)]")
                }
        }
}
//MARK: - cache operation
extension GroupItem{
        public static func deleteAll(){
                cache.removeAll()
        }
        public static func loadCachedFromDB() {
                guard let owner = Wallet.shared.Addr else {
                        return
                }
                do{
                        var result: [GroupItem] = []
                        result = try CDManager.shared.Get(entity: CDEntityName,
                                                          predicate: NSPredicate(format: "isDelete == false AND owner == %@", owner),
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
}

//MARK: - private  operation
extension GroupItem {
        
        private static func isDeleted(group:GroupItem) -> Bool{
                
                let owner = Wallet.shared.Addr!
                
                if group.isDelete{
                        return true
                }
                
                for memID in group.memberIds{
                        if memID == owner{
                                return false
                        }
                }
                
                return true
        }
        
        public static func CheckGroupIsDeleted(gid:String){ServiceDelegate.workQueue.async {
                
                var obj: GroupItem?
                do{
                        obj = try CDManager.shared.GetOne(entity: CDEntityName,
                                                          predicate: NSPredicate(format: "gid == %@", gid))
                }catch let err{
                        print("------->>>", err)
                        NotificationCenter.default.post(name:NotifyGroupDeleteChanged,
                                                        object: gid,
                                                        userInfo:nil)
                }
                if let group = obj{
                        
                        guard isDeleted(group: group) else{
                                return
                        }
                        NotificationCenter.default.post(name:NotifyGroupDeleteChanged,
                                                        object: gid,
                                                        userInfo:nil)
                        return
                        
                }
                
                
                guard let newGroup = syncGroupMetaFromChainBy(groupID: gid) else{
                        print("------>>> no group data on chain for:=>", gid)
                        NotificationCenter.default.post(name:NotifyGroupDeleteChanged,
                                                        object: gid,
                                                        userInfo:nil)
                        return
                }
                
                guard isDeleted(group: newGroup) else{
                        return
                }
                
                NotificationCenter.default.post(name:NotifyGroupDeleteChanged,
                                                object: gid,
                                                userInfo:nil)
                
                
        }}
        
        private static func getGroupFromMemOrDB(_ gid: String) -> GroupItem? {
                if let grp = cache[gid]{
                        return grp
                }
                let owner = Wallet.shared.Addr!
                var obj: GroupItem?
                obj = try? CDManager.shared.GetOne(entity: CDEntityName,
                                                   predicate: NSPredicate(format: "isDelete == false AND gid == %@ AND owner == %@", gid, owner))
                guard let item = obj else{
                        cache.removeValue(forKey: gid)
                        return nil
                }
                cache[gid] = item
                cache.updateValue(item, forKey: gid)
                return item
        }
        
        private static func syncGroupToDB(_ group: GroupItem)throws{
                
                group.owner = Wallet.shared.Addr!
                try CDManager.shared.UpdateOrAddOne(entity: CDEntityName,
                                                    m: group,
                                                    predicate: NSPredicate(format: "gid == %@ AND owner == %@",
                                                                           group.gid, group.owner))
                if group.isDelete{
                        cache.removeValue(forKey: group.gid)
                        return
                }
                
                cache[group.gid] = group
                cache.updateValue(group, forKey: group.gid)
        }
        
        private static func deleteGroupFromDB(_ gid: String)throws{
                try CDManager.shared.Update(entity: CDEntityName,
                                            predicate: NSPredicate(format: "gid == %@", gid)){
                        obj in
                        
                        guard let group  = obj as? CDGroup else{
                                return
                        }
                        group.isDelete = true
                }
                
                cache.removeValue(forKey: gid)
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
                        group.avatar = nilAvatar
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
                cObj.gid = self.gid
                cObj.name = self.groupName
                cObj.owner = self.owner
                cObj.members = try NSKeyedArchiver.archivedData(withRootObject: self.memberIds, requiringSecureCoding: true)//self.memberIds as NSObject
                cObj.unixTime = self.unixTime
                cObj.leader = self.leader
                cObj.isDelete = self.isDelete
                cObj.avatar = self.avatar
                cObj.nonce = self.nonce
        }
        
        func initByObj(obj: NSManagedObject) throws {
                guard let cObj = obj as? CDGroup else {
                        throw NJError.coreData("Cast to CDGroup failed")
                }
                
                self.gid = cObj.gid ?? "<->"
                self.groupName = cObj.name
                self.owner = cObj.owner!
                self.memberIds = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSArray.self, from: cObj.members ?? Data()) as? [String] ?? []
                self.unixTime = cObj.unixTime
                self.leader = cObj.leader!
                self.avatar = cObj.avatar
                self.isDelete = cObj.isDelete
                self.nonce = cObj.nonce
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
                
                ChatItem.updateLatestrMsg(pid: gid,
                                          msg: "New Group",
                                          time: item.unixTime * 1000,
                                          unread: 0, isGrp: true)
                CDManager.shared.saveContext()
                return item
        }
        
        
        public static func DismissGroup(gid: String) -> NJError? {
                do{
                        try GroupItem.deleteGroupFromDB(gid)
                        try ChatItem.remove(gid)
                        
                        var error: NSError?
                        _ = ChatLibDismissGroup(gid, &error)
                        if error != nil {
                                return NJError.group(error!.localizedDescription)
                        }
                        
                        MessageItem.removeRead(gid)
                        CDManager.shared.saveContext()
                        
                        return nil
                }catch let err{
                        return NJError.group("dissmiss failed \(err.localizedDescription)")
                }
        }
        
        public static func updateGroupName(group:GroupItem, newName:String)->Error?{
                
                var err: NSError?
                let hashTx = ChatLibChangeGroupName(group.gid, newName, &err)
                
                if let e = err{
                        return e
                }
                
                do{
                        group.groupName = newName
                        try syncGroupToDB(group)
                }catch let err{
                        return err
                }
                CDManager.shared.saveContext()
                print("------>>>group name update hash:\(hashTx)")
                return nil
        }
        
        public static func SyncAllGroupDataFromChainAtOnce(){
                
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
                        
                        do {
                                group.avatar = nilAvatar
                                try syncGroupToDB(group)
                                
                        }catch let err {
                                print("---[update grp]---\(err.localizedDescription )")
                                continue
                        }
                        
                        GroupItem.cache[group.gid] = group
                }
        }
        
        public static func AddMemberToGroup(group: GroupItem, newIds: [String]) -> NJError? {
                
                do {
                        let idsData = try JSON(newIds).rawData()
                        var err: NSError?
                        let hash_tx = ChatLibAddGroupMembers(group.gid, idsData, &err)
                        if let e = err{
                                return NJError.group("\(e.localizedDescription)")
                        }
                        print("------>>>add group member to chain success:=>", hash_tx)
                        group.memberIds.append(contentsOf: newIds)
                        try GroupItem.syncGroupToDB(group)
                        CDManager.shared.saveContext()
                } catch let err{
                        return NJError.group("\(err.localizedDescription)")
                }
                return nil
        }
        
        public static func KickOutUser(group: GroupItem, kickUserId: [String:Bool]) -> NJError? {
                do{
                        var err:NSError?
                        var uidArr:[String] = []
                        for uid in kickUserId {
                                uidArr.append(uid.key)
                        }
                        
                        let memJsonData = try JSON(uidArr).rawData()
                        let hash_tx = ChatLibKickOutMembers(group.gid, memJsonData, &err)
                        if let e = err{
                                return NJError.group("\(e.localizedDescription)")
                        }
                        
                        print("------>>>delete group member from chain success:=>", hash_tx)
                        group.memberIds.removeAll { uid in
                                kickUserId[uid] == true
                        }
                        try GroupItem.syncGroupToDB(group)
                        CDManager.shared.saveContext()
                }catch let err{
                        return NJError.group("\(err.localizedDescription)")
                }
                return nil
        }
        
        public static func QuitFromGroup(group: GroupItem)  -> NJError? {
                do{
                        let addr = Wallet.shared.Addr!
                        guard group.memberIds.contains(addr) else{
                                return NJError.group("no such member in this group")
                        }
                        var err:NSError?
                        let hash_tx = ChatLibQuitFromGroup(group.gid, &err)
                        if let e = err{
                                return NJError.group("\(e.localizedDescription)")
                        }
                        print("------>>>quit from group success:=>", hash_tx)
                        guard let idx = group.memberIds.firstIndex(of: addr) else{
                                return nil
                        }
                        group.memberIds.remove(at: idx)
                        try GroupItem.syncGroupToDB(group)
                        CDManager.shared.saveContext()
                        return nil
                }catch let err{
                        return NJError.group("\(err.localizedDescription)")
                }
        }
}

//MARK: - call from or to websocket
extension GroupItem{
        
        public static func getMembersOfGroup(gid: String) -> Data? {
                guard let grpItem = GroupItem.getGroupFromMemOrDB(gid) else {
                        return nil
                }
                
                var ids: [String] = grpItem.memberIds
                ids.append(grpItem.leader)
                
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
                        
                        if let _ = getGroupFromMemOrDB(gid){
                                continue
                        }
                        
                        let _ = syncGroupMetaFromChainBy(groupID: gid)
                }
                
                return nil
        }
        
        public static func GroupMeataNotified(data: Data){
                
                guard let newItem = initByJson(json: JSON(data)) else{
                        return
                }
                
                let oldItem = getGroupFromMemOrDB(newItem.gid)
                
                guard oldItem == nil || oldItem!.nonce != newItem.nonce else{
                        print("------>>>[GroupMeataNotified] same group nonce=>", newItem.nonce)
                        return
                }
                
                let groupID = newItem.gid
                defer{
                        CDManager.shared.saveContext()
                }
                do {
                        
                        print("------>>>new group item", newItem.ToString())
                        
                        if newItem.isDelete || !newItem.memberIds.contains(Wallet.shared.Addr!){
                                try deleteGroupFromDB(groupID)
                                try ChatItem.remove(groupID)
                                MessageItem.removeRead(groupID)
                                
                                NotificationCenter.default.post(name:NotifyGroupDeleteChanged,
                                                                object: groupID,
                                                                userInfo:nil)
                                return
                        }
                        
                        newItem.avatar = nilAvatar//TODO::to be tested
                        try syncGroupToDB(newItem)
                        ChatItem.updateLatestrMsg(pid: groupID,
                                                  msg: "group update",
                                                  time: newItem.unixTime * 1000,
                                                  unread: 0, isGrp: true)
                        NotificationCenter.default.post(name:NotifyGroupChanged,
                                                        object: groupID,
                                                        userInfo:nil)
                        
                }catch let err{
                        print("------>>>[GroupMeataNotified] error=>", err.localizedDescription)
                }
        }
}
