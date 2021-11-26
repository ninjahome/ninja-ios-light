//
//  GroupItem.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/8/8.
//

import Foundation
import CoreData
import ChatLib

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
    
    var gid: String?
    var groupName: String?
    var memberIds: NSArray?
    var memberNicks: NSArray?
    var owner: String?
    var unixTime: Int64 = 0
    var leader: String?
    var banTalked: Bool = false
    
    var memberInfos: Dictionary<String, String> = [:]
    
    override init() {
        super.init()
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
        result = try? CDManager.shared.Get(entity: "CDGroup", predicate: NSPredicate(format: "owner == %@", owner), sort: [["groupName" : true]])
        
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
    
    public static func NewGroup(ids: [String], nicks: [String], groupName: String) -> String? {
        
        let groupId = ChatLib.ChatLibNewGroupId()
        
            guard let data = ChatLib.ChatLibPackCreateGroup(nicks.toString(), groupId, groupName) else{
                    NSLog("pack data failed")
                    return nil
            }
            let msgID = ChatLib.ChatLibSend(ids.toString(), data, true)
            //TODO:: save msgID and wait success callback
            return groupId
    }
    
    public static func AddMemberToGroup(group: GroupItem, newIds: [String]) -> NJError? {
        var error: NSError?
        let to = group.memberIds as! [String]
        let nicks = group.memberNicks as! [String]
        guard let data = ChatLib.ChatLibPackJoinGroup(nicks.toString(),
                                     group.gid,
                                     group.groupName,
                                     group.leader,
                                     group.banTalked,
                                    newIds.toString()) else{
                return NJError.msg("pack error failed")
        }
        
            let msgID = ChatLib.ChatLibSend(to.toString(), data, true)
            //TODO:: save msgID and wait success callback
            return nil
    }
    
    public static func KickOutUser(to: String?, groupId: String, leader: String, kickUserId: String) -> NJError? {
        
            guard let data = ChatLib.ChatLibPackKickOutUser(groupId, leader, kickUserId) else{
                    return NJError.msg("pack error failed")
            }
            let msgID = ChatLib.ChatLibSend(to, data, true)
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
        
        let nicks = group.memberInfos.map { (key: String, value: String) in
            return value
        }
        
        group.memberIds = newIds as NSArray
        group.memberNicks = nicks as NSArray
        
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
        let ids = groupItem.memberIds as! [String]
        let gid = groupItem.gid!
        
        var data: Data?
        if groupItem.leader == Wallet.shared.Addr! {
            data = ChatLib.ChatLibPackDismissGroup(Wallet.shared.Addr, gid)

        } else {
                data = ChatLib.ChatLibPackQuitGroup(gid)
        }
            guard let d = data else{
                    return NJError.msg("pack data error")
            }
            let msgID = ChatLib.ChatLibSend(ids.toString(), d, true)
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
            
            let nicks = group.memberInfos.map { (key: String, value: String) in
                return value
            }
            
            group.memberIds = newIds as NSArray
            group.memberNicks = nicks as NSArray
            
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
    
    public static func SyncGroupFromMe(by gid: String) -> String {
        guard let group = GroupItem.GetGroup(gid) else {
            return ""
        }

        var groupDict: Dictionary<String, Any> = [:]
        groupDict["group_id"] = group.gid
        groupDict["group_name"] = group.groupName
        groupDict["owner_id"] = group.leader
        groupDict["ban_talking"] = group.banTalked
        groupDict["member_id"] = group.memberIds
        groupDict["nick_name"] = group.memberNicks
        let res = getJSONStringFromDictionary(dictionary: groupDict as NSDictionary)
        print(res)
        return res
    }
    
    public static func SyncGroup(to: String?, groupId: String?) -> NJError? {
        var error: NSError?
        ChatLib.ChatLibSyncGroup(to, groupId, &error)
        
        if error != nil {
            return NJError.msg(error!.localizedDescription)
        }
        
        return nil
    }
    
    public static func CheckGroupExist(groupId: String, syncTo: String?) -> Bool {
        if GroupItem.cache[groupId] == nil {
            _ = GroupItem.SyncGroup(to: syncTo, groupId: groupId)
            return false
        }
        
        return true
    }
}

extension GroupItem: ModelObj {
    
    func fullFillObj(obj: NSManagedObject) throws {
        guard let cObj = obj as? CDGroup else {
            throw NJError.coreData("Cast to CDGroup failed")
        }
        self.UpdateSelfInfos()
        cObj.gid = self.gid
        cObj.groupName = self.groupName
        cObj.owner = self.owner
        cObj.memberIds = self.memberIds
        cObj.memberNicks = self.memberNicks
        cObj.unixTime = self.unixTime
        cObj.leader = self.leader
        cObj.banTalked = self.banTalked
        
    }
    
    func initByObj(obj: NSManagedObject) throws {
        guard let cObj = obj as? CDGroup else {
            throw NJError.coreData("Cast to CDGroup failed")
        }
        
        self.gid = cObj.gid
        self.groupName = cObj.groupName
        self.owner = cObj.owner
        self.memberIds = cObj.memberIds as? NSArray
        self.memberNicks = cObj.memberNicks as? NSArray
        self.unixTime = cObj.unixTime
        self.leader = cObj.leader
        self.banTalked = cObj.banTalked
        
        self.UpdateSelfInfos()
//        let ids = self.memberIds!
//        let nicks = self.memberNicks!
//        let count = min(ids.count, nicks.count)
//
//        for i in 0 ..< count {
//            self.memberInfos[ids[i] as! String] = nicks[i] as? String
//        }
        
    }

    func UpdateSelfInfos() {
        let ids = self.memberIds!
        let nicks = self.memberNicks!
        let count = min(ids.count, nicks.count)
        
        for i in 0 ..< count {
            self.memberInfos[ids[i] as! String] = nicks[i] as? String
        }

    }


}
