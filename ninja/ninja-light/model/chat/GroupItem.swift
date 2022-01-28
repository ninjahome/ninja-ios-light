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
        var gid: String?
        var groupName: String?
        var memberIds: [String] = []
//        var memberNicks: NSArray?
        var owner: String?
        var unixTime: Int64 = 0
        var leader: String?
//        var banTalked: Bool = false
        var isDelete: Bool = false
        var avatar: Data?

        var memberInfos: Dictionary<String, String> = [:]

        override init() {
                super.init()
        }
        
        public static func initByData(_ data: Data) -> GroupItem? {
                if let objJson = try? JSON(data: data) {
                        let grp = GroupItem()
                        grp.gid = objJson["gid"].string
                        grp.nonce = objJson["nonce"].int64
                        grp.leader = objJson["owner"].string
                        grp.groupName = objJson["name"].string
                        grp.isDelete = objJson["deleted"].bool ?? false
                        guard let memIds = objJson["members"].dictionaryObject?.keys else {
                                return nil
                        }
                        var ids : [String] = []
                        for k in memIds {
                                let uid = String(k)
                                ids.append(uid)
                        }
                        grp.memberIds = ids
                        grp.owner = Wallet.shared.Addr!
                        return grp
                }
                return nil
        }
        
        public static func getMembersOfGroup(gid: String) -> Data? {
                guard let grpItem = GroupItem.GetGroup(gid) else {
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
    
        public static func GetGroup(_ gid: String) -> GroupItem? {
                var obj: GroupItem?
                let owner = Wallet.shared.Addr!

                obj = try? CDManager.shared.GetOne(entity: "CDGroup", predicate: NSPredicate(format: "gid == %@ AND owner == %@", gid, owner))

                if obj != nil {
                        cache[gid] = obj
                }
                return obj
        }

        public static func UpdateGroup(_ group: GroupItem) -> NJError? {
                group.owner = Wallet.shared.Addr

                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDGroup", m: group, predicate: NSPredicate(format: "gid == %@ AND owner == %@", group.gid!, group.owner!))
                        cache[group.gid!] = group
                } catch let err {
                        return NJError.group(err.localizedDescription)
                }
                return nil
        }
    
        public static func DeleteGroup(_ gid: String) -> NJError? {
                let owner = Wallet.shared.Addr!
                do {
                        try CDManager.shared.Delete(entity: "CDGroup", predicate: NSPredicate(format: "gid == %@ AND owner == %@", gid, owner))

                        cache.removeValue(forKey: gid)
                } catch let err {
                        return NJError.group(err.localizedDescription)
                }
                return nil
        }
    
        public static func LocalSavedGroup() {
                guard let owner = Wallet.shared.Addr else {
                        return
                }
                var result: [GroupItem]?
                result = try? CDManager.shared.Get(entity: "CDGroup", predicate: NSPredicate(format: "owner == %@", owner), sort: [["name" : true]])

                guard let arr = result else {
                        return
                }

                for obj in arr {
                        cache[obj.gid!] = obj
                        print("LOCAL SAVED GROUP:\(obj)")
                }
        }
    
        public static func CacheArray() -> [GroupItem] {
                return Array(cache.values)
        }
        
        public static func getGroupAvatar(ids: [String]) -> Data? {
                let defaultAvatarData = Data(UIImage(named: "logo_img")!.jpegData(compressionQuality: 1)!)
                var counter = 0
                var imgData = defaultAvatarData
                for id in ids{
                        counter += 1
                        if counter > 9{
                                break
                        }
                        
                        if id == Wallet.shared.Addr && Wallet.shared.avatarData != nil{
                                imgData = Wallet.shared.avatarData!
                        }else{
                                if let data = AccountItem.GetAccount(id)?.Avatar{
                                        imgData = data
                                }
                        }
                        ChatLibAddImg(imgData)
                }
                var err: NSError?
                if let avatar = ChatLibCommitImg(&err) {
                        return avatar
                }
                NSLog("---[group image]---\(err?.localizedDescription ?? "")")
                return nil
        }

        public static func NewGroup(ids: [String], groupName: String?) -> String? {
                var error: NSError?
                let jsonStr = JSON(ids).description
                guard let data = jsonStr.data(using: .utf8) else {
                        return nil
                }
                let gid = ChatLibCreateGroup(groupName, data, &error)
                
                if error != nil {
                        print("new grp err: \(String(describing: error?.localizedDescription))")
                        return nil
                }
                return gid
        }
        
        public static func syncGroup(_ gid: String?) -> GroupItem? {
                var err: NSError?
                guard let data = ChatLibGroupMeta(gid, &err) else {
                        return nil
                }
                guard let group = GroupItem.initByData(data) else {
                        return nil
                }
                if AccountItem.GetAccount(group.leader!) == nil {
                        _ = AccountItem.loadAccountDetailFromChain(addr: group.leader!)
                }
                
 
                for i in group.memberIds {
                        if AccountItem.GetAccount(i ) == nil {
                                _ = AccountItem.loadAccountDetailFromChain(addr: i )
                        }
                }
                if group.avatar == nil{
                        var allIds = group.memberIds
                        allIds.append(group.leader!)
                        if let grpImg = GroupItem.getGroupAvatar(ids: allIds) {
                                group.avatar = grpImg
                        }
                }
                
                
                if let err = UpdateGroup(group) {
                        NSLog("---[update grp]---\(err.localizedDescription ?? "")")
                }
                return group
        }
    
        public static func AddMemberToGroup(group: GroupItem, newIds: [String]) -> NJError? {
                var error: NSError?
                let to = group.memberIds
                let idsData = ChatLibUnmarshalGoByte(to.toString())
//                let nicks = group.memberNicks as! [String]
                ChatLibAddGroupMembers(group.gid, idsData, &error)
        
//                guard let data = ChatLib.ChatLibPackJoinGroup(nicks.toString(),
//                                     group.gid,
//                                     group.groupName,
//                                     group.leader,
//                                     group.banTalked,
//                                    newIds.toString()) else{
//                        return NJError.msg("pack error failed")
//                }

                //            let msgID = ChatLib.ChatLibSend(to.toString(), data, true)
                //TODO:: save msgID and wait success callback
                return nil
        }
    
        public static func KickOutUser(to: String?, groupId: String, leader: String, kickUserId: String) -> NJError? {
        
//            guard let data = ChatLib.ChatLibPackKickOutUser(groupId, leader, kickUserId) else{
//                    return NJError.msg("pack error failed")
//            }
//            let msgID = ChatLib.ChatLibSend(to, data, true)
            //TODO:: save msgID and wait success callback
                return nil
        }
    
        public static func KickOutUserNoti(group: GroupItem, kickIds: String?, from: String) throws {
                guard let kick = kickIds?.toArray() else {
                        return
                }

                if kick.contains(Wallet.shared.Addr!) {
                        let _ = GroupItem.DeleteGroup(group.gid!)
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

//                let nicks = group.memberInfos.map { (key: String, value: String) in
//                        return value
//                }

                group.memberIds = newIds
//                group.memberNicks = nicks as NSArray

                if let err = GroupItem.UpdateGroup(group) {
                        throw NJError.coreData("kick out update group failed.\(String(describing: err.localizedDescription))")
                }

                let NotiKey_ids = "KICK_IDS"
                let NotiKey_from = "KICK_FROM"
                NotificationCenter.default.post(name: NotifyKickOutGroup,
                                        object: self,
                                        userInfo: [NotiKey_ids: kickIds!, NotiKey_from: from])

        }
    
        public static func QuitGroup(groupItem: GroupItem) -> NJError? {
//                let ids = groupItem.memberIds as! [String]
                let gid = groupItem.gid!
                var error: NSError?
                _ = ChatLibDismissGroup(gid, &error)
                if error != nil {
                        return NJError.group(error!.localizedDescription)
                }
//                var data: Data?
//                if groupItem.leader == Wallet.shared.Addr! {
//                        data = ChatLib.ChatLibPackDismissGroup(Wallet.shared.Addr, gid)
//
//                } else {
//                        data = ChatLib.ChatLibPackQuitGroup(gid)
//                }
//                guard let d = data else{
//                        return NJError.msg("pack data error")
//                }
                //            let msgID = ChatLib.ChatLibSend(ids.toString(), d, true)
                //TODO:: save msgID and wait success callback

                _ = GroupItem.DeleteGroup(gid)
                ChatItem.remove(gid)
                MessageItem.removeRead(gid)

                return nil
        }
    
        public static func QuitGroupNoti(from: String?, groupId: String, quitId: String) throws {
                if let group = GroupItem.GetGroup(groupId) {
                        group.memberInfos.removeValue(forKey: quitId)

                        let newIds = group.memberInfos.map { (key: String, value: String) in
                                return key
                        }

//                        let nicks = group.memberInfos.map { (key: String, value: String) in
//                                return value
//                        }

                        group.memberIds = newIds
//                        group.memberNicks = nicks as NSArray

                        if let err = GroupItem.UpdateGroup(group) {
                                throw NJError.coreData("quit group update group failed.\(String(describing: err.localizedDescription))")
                        }

                }

        }

        public static func GetAvatarText(by gid: String) -> String {
                let gItem = GroupItem.cache[gid]
                if let nick = gItem?.groupName {
                        return String(nick.prefix(2))
                }

                return String(gid.prefix(2))

        }
    
//        public static func SyncGroupFromMe(by gid: String) -> String {
//                guard let group = GroupItem.GetGroup(gid) else {
//                        return ""
//                }
//
//                var groupDict: Dictionary<String, Any> = [:]
//                groupDict["group_id"] = group.gid
//                groupDict["group_name"] = group.groupName
//                groupDict["owner_id"] = group.leader
//                groupDict["ban_talking"] = group.banTalked
//                groupDict["member_id"] = group.memberIds
//                groupDict["nick_name"] = group.memberNicks
//                let res = getJSONStringFromDictionary(dictionary: groupDict as NSDictionary)
//                print(res)
//                return res
//        }
//
//        public static func SyncGroup(to: String?, groupId: String?) -> NJError? {
//                var error: NSError?
//                
//                
//                ChatLib.ChatLibSyncGroup(to, groupId, &error)
//
//                if error != nil {
//                        return NJError.msg(error!.localizedDescription)
//                }
//
//                return nil
//        }
//    
//        public static func CheckGroupExist(groupId: String, syncTo: String?) -> Bool {
//                if GroupItem.cache[groupId] == nil {
//                        _ = GroupItem.SyncGroup(to: syncTo, groupId: groupId)
//                        return false
//                }
//
//                return true
//        }
}

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

                self.gid = cObj.gid
                self.groupName = cObj.name
                self.owner = cObj.owner
                self.memberIds = cObj.members as? [String] ?? []
//                self.memberNicks = cObj.memberNicks as? NSArray
                self.unixTime = cObj.unixTime
                self.leader = cObj.leader
                self.avatar = cObj.avatar
                self.isDelete = cObj.isDelete
//                self.UpdateSelfInfos()
                //        let ids = self.memberIds!
                //        let nicks = self.memberNicks!
                //        let count = min(ids.count, nicks.count)
                //
                //        for i in 0 ..< count {
                //            self.memberInfos[ids[i] as! String] = nicks[i] as? String
                //        }

        }

//        func UpdateSelfInfos() {
//                let ids = self.memberIds!
//                let nicks = self.memberNicks!
//                let count = min(ids.count, nicks.count)

//                for i in 0 ..< ids.count {
//                        self.memberInfos[ids[i] as! String] = nicks[i] as? String
//                }
//        }


}
