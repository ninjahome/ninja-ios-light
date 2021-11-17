//
//  WebsocketCallback.swift
//  ninja-light
//
//  Created by wesley on 2021/4/6.
//

import Foundation
//import SwiftyJSON
import ChatLib
import UIKit

class WebsocketSrv: NSObject {
    public static var shared = WebsocketSrv()
    
    public static let netQueue = DispatchQueue.init(label: "Connect Queue", qos: .userInteractive)
    
    public static let textMsgQueue = DispatchQueue.init(label: "Sending Text Queue")
    public static let imageMsgQueue = DispatchQueue.init(label: "Sending Image Queue")
    public static let voiceMsgQueue = DispatchQueue.init(label: "Sending Voice Queue")
    public static let locationMsgQueue = DispatchQueue.init(label: "Sending Location Queue")
    
    override init() {
        super.init()
    }
    
    func IsOnline() -> Bool {
        let online = ChatLib.ChatLibWSIsOnline()
        return online
    }
    
    func Online() -> Error? {
        var err:NSError? = nil
//        WebsocketSrv.netQueue.async {
            ChatLib.ChatLibWSOnline(&err)
//        }
        print("online err \(String(describing: err?.localizedDescription))")
        return err
    }
    
    func Offline() {
        ChatLib.ChatLibWSOffline()
    }
    
    func SendIMMsg(cliMsg: CliMessage, retry: Bool = false, onStart: @escaping()-> Void, onCompletion: @escaping(Bool) -> Void) {
        var error:NSError?
        var isGroup: Bool = false
        var res: Bool = false
        let gid = cliMsg.groupId
        
        if gid != nil {
            isGroup = true
        }

        if retry {
            onStart()
        } else {
            let msg = MessageItem.addSentIM(cliMsg: cliMsg)
            onStart()
            ChatItem.updateLastMsg(peerUid: isGroup ? gid! : cliMsg.to!,
                                   msg: msg.coinvertToLastMsg(),
                                   time: msg.timeStamp,
                                   unread: 0,
                                   isGroup: isGroup)
        }
        
        switch cliMsg.type {
            case .plainTxt:
                WebsocketSrv.textMsgQueue.async {
                    if isGroup {
                        ChatLib.ChatLibWriteGroupMessage(cliMsg.to, gid, cliMsg.textData, &error)
                    } else {
                        ChatLib.ChatLibWriteMessage(cliMsg.to, cliMsg.textData, &error)
                    }
                    
                    if error == nil {
                        res = true
                    }
                    
                    DispatchQueue.main.async {
                        onCompletion(res)
                    }
                }
            case .image:
                WebsocketSrv.imageMsgQueue.async {
                    if isGroup {
                        ChatLib.ChatLibWriteImageGroupMessage(cliMsg.to, cliMsg.imgData, gid, &error)
                    } else {
                        ChatLib.ChatLibWriteImageMessage(cliMsg.to, cliMsg.imgData, &error)
                    }
                    print("send image success_____")
                    if error == nil {
                        res = true
                    }
                    
                    DispatchQueue.main.async {
                        onCompletion(res)
                    }
                }
            case .voice:
                WebsocketSrv.voiceMsgQueue.async {
                    if isGroup {
                        ChatLib.ChatLibWriteVoiceGroupMessage(cliMsg.to, cliMsg.audioData?.content, cliMsg.audioData?.duration ?? 0, gid, &error)
                    } else {
                        ChatLib.ChatLibWriteVoiceMessage(cliMsg.to, cliMsg.audioData?.content, cliMsg.audioData?.duration ?? 0, &error)
                    }
                    if error == nil {
                        res = true
                    }
                    
                    DispatchQueue.main.async {
                        onCompletion(res)
                    }
                }
            case .location:
                WebsocketSrv.locationMsgQueue.async {
                    if isGroup {
                        ChatLib.ChatLibWriteLocationGroupMessage(cliMsg.to, cliMsg.locationData!.lo, cliMsg.locationData!.la, cliMsg.locationData!.str, gid, &error)
                    } else {
                        ChatLib.ChatLibWriteLocationMessage(cliMsg.to, cliMsg.locationData!.lo, cliMsg.locationData!.la, cliMsg.locationData!.str, &error)
                    }
                    if error == nil {
                        res = true
                    }
                    
                    DispatchQueue.main.async {
                        onCompletion(res)
                    }
                }
            default:
                print("send msg: no such type")
        }
    }
}

extension WebsocketSrv: ChatLibUICallBackProtocol {
        func endPointChanged(_ newEndPoint: String?, p1: Error?) {
                print(newEndPoint ?? "")
        }
        
        func licenseChanged(_ newTime: Int64, p1: Error?) {
                print(newTime)
        }
        
    func fileMessage(_ from: String?, to: String?, payload: Data?, size: Int, name: String?) throws {
        print("file msg size\(size)")
    }
    
    func imageMessage(_ from: String?, to: String?, payload: Data?, time: Int64) throws {
        let owner = Wallet.shared.Addr!
        if owner != to {
            throw NJError.msg("this image im is not for me")
        }
        let cliMsg = CliMessage.init(to: to!, imgData: payload!)
        let msg = MessageItem.init(cliMsg: cliMsg, from: from!, time: time, out: false)
        MessageItem.receivedIM(msg: msg)
        ChatItem.updateLastMsg(peerUid: from!, msg: msg.coinvertToLastMsg(), time: time, unread: 1)
        
    }
    
    func locationMessage(_ from: String?, to: String?, l: Float, a: Float, name: String?, time: Int64) throws {
        let owner = Wallet.shared.Addr!
        if owner != to {
            throw NJError.msg("this location im is not for me")
        }
        let localMsg = locationMsg()
        localMsg.la = a
        localMsg.lo = l
        localMsg.str = name ?? "[]"
        let cliMsg = CliMessage.init(to: to!, locationData: localMsg)
        let msg = MessageItem.init(cliMsg: cliMsg, from: from!, time: time, out: false)
        MessageItem.receivedIM(msg: msg)
        ChatItem.updateLastMsg(peerUid: from!, msg: msg.coinvertToLastMsg(), time: time, unread: 1)
        print("location msg received")
    }
    
    func voiceMessage(_ from: String?, to: String?, payload: Data?, length: Int, time: Int64) throws {
        let owner = Wallet.shared.Addr!
        if owner != to {
            throw NJError.msg("this voice im is not for me")
        }
        let cliMsg = CliMessage.init(to: to!, audioD: payload!, length: length)
        let msg = MessageItem.init(cliMsg: cliMsg, from: from!, time: time, out: false)
        MessageItem.receivedIM(msg: msg)
        ChatItem.updateLastMsg(peerUid: from!, msg: msg.coinvertToLastMsg(), time: time, unread: 1)
        
    }
    
    func textMessage(_ from: String?, to: String?, payload: String?, time: Int64) throws {
        let owner = Wallet.shared.Addr!
        if owner != to {
            throw NJError.msg("this txt im is not for me")
        }
        let cliMsg = CliMessage.init(to: to!, txtData: payload!)
        let msg = MessageItem.init(cliMsg: cliMsg, from: from!, time: time, out: false)
        MessageItem.receivedIM(msg: msg)
        ChatItem.updateLastMsg(peerUid: from!, msg: msg.coinvertToLastMsg(), time: time, unread: 1)
    }
    
    func webSocketClosed() {
        NSLog("======> websocket is closed")
        NotificationCenter.default.post(name: NotifyWebsocketOffline,
                                        object: self,
                                        userInfo: nil)
    }
    
    func webSocketDidOnline(){
            NSLog("======> websocket did online")
            NotificationCenter.default.post(name: NotifyWebsocketOnline,
                                            object: self,
                                            userInfo: nil)
    }
    
    func gFileMessage(_ from: String?, groupId: String?, payload: Data?, size: Int, name: String?) throws {
        if !GroupItem.CheckGroupExist(groupId: groupId!, syncTo: from) {
            return
        }

        print("\(String(describing: name))-file msg size:\(size)")
    }
    
    func gImageMessage(_ from: String?, groupId: String?, payload: Data?, time: Int64) throws {
        if !GroupItem.CheckGroupExist(groupId: groupId!, syncTo: from) {
            return
        }

        let owner = Wallet.shared.Addr!
        let cliMsg = CliMessage.init(to: owner, imgData: payload!, groupId: groupId)
        let msg = MessageItem.init(cliMsg: cliMsg, from: from!, time: time, out: false)
        MessageItem.receivedIM(msg: msg)
        ChatItem.updateLastMsg(peerUid: groupId!, msg: msg.coinvertToLastMsg(), time: time, unread: 1, isGroup: true)
    }
    
    func gLocationMessage(_ from: String?, groupId: String?, l: Float, a: Float, name: String?, time: Int64) throws {
        if !GroupItem.CheckGroupExist(groupId: groupId!, syncTo: from) {
            return
        }

        let owner = Wallet.shared.Addr!
        let cliMsg = CliMessage.init(to: owner, la: a, lo: l, describe: name ?? "", groupId: groupId)
        let msg = MessageItem.init(cliMsg: cliMsg, from: from!, time: time, out: false)
        
        MessageItem.receivedIM(msg: msg)
        ChatItem.updateLastMsg(peerUid: groupId!, msg: msg.coinvertToLastMsg(), time: time, unread: 1, isGroup: true)
    }
    
    func gVoiceMessage(_ from: String?, groupId: String?, payload: Data?, length: Int, time: Int64) throws {
        if !GroupItem.CheckGroupExist(groupId: groupId!, syncTo: from) {
            return
        }

        let owner = Wallet.shared.Addr!
        let cliMsg = CliMessage.init(to: owner, audioD: payload!, length: length, groupId: groupId)
        let msg = MessageItem.init(cliMsg: cliMsg, from: from!, time: time, out: false)
        MessageItem.receivedIM(msg: msg)
        ChatItem.updateLastMsg(peerUid: groupId!, msg: msg.coinvertToLastMsg(), time: time, unread: 1, isGroup: true)
    }
    
    func gTextMessage(_ from: String?, groupId: String?, payload: String?, time: Int64) throws {
        if !GroupItem.CheckGroupExist(groupId: groupId!, syncTo: from) {
            return
        }
        let owner = Wallet.shared.Addr!
        let cliMsg = CliMessage.init(to: owner, txtData: payload!, groupId: groupId)
        let msg = MessageItem.init(cliMsg: cliMsg, from: from!, time: time, out: false)
        MessageItem.receivedIM(msg: msg)
        ChatItem.updateLastMsg(peerUid: groupId!, msg: msg.coinvertToLastMsg(), time: time, unread: 1, isGroup: true)
    }
    
    func banTalking(_ groupId: String?, banned: Bool) throws {
        print("ban talking\(String(describing: groupId))")
    }

    func createGroup(_ groupId: String?, groupName: String?, owner: String?, memberIdList: String?, memberNickNameList: String?) throws {
        
        let account = Wallet.shared.Addr!
        let group = GroupItem.init()
        group.gid = groupId
        group.groupName = groupName
        group.owner = account
        group.leader = owner
        group.memberIds = memberIdList?.toArray()
        group.memberNicks = memberNickNameList?.toArray()
        
        if let err = GroupItem.UpdateGroup(group) {
            print("Update group erro.\(String(describing: err.localizedDescription))")
        }
        print("create new group")
    }

    func dismisGroup(_ groupId: String?) throws {
        guard let gid = groupId else {
            return
        }
        MessageItem.removeRead(gid)
        
        if let err = GroupItem.DeleteGroup(gid) {
            print("Dismiss group error.\(String(describing: err.localizedDescription))")
        }
        
        print("dismiss group: \(String(describing: groupId)) success")
    }

    func joinGroup(_ from: String?, groupId: String?, groupName: String?, owner: String?, memberIdList: String?, memberNickNameList: String?, newIdList: String?, banTalkding: Bool) throws {
        
        let account = Wallet.shared.Addr!
        
        var group = GroupItem.init()
        group.owner = account
        group.groupName = groupName
        group.gid = groupId
        group.unixTime = Int64(Date().timeIntervalSince1970)
        group.banTalked = banTalkding
        
        if let item = GroupItem.GetGroup(groupId!) {
            group = item
            if group.owner != account {
                print("This group is not mine")
                return
            }
        }
        
        group.memberIds = memberIdList?.toArray()
        group.memberNicks = memberNickNameList?.toArray()
        
        _ = GroupItem.UpdateGroup(group)

        let NotiKey_group = "GROUP_ID"
        let NotiKey_newList = "NEW_LIST"
        NotificationCenter.default.post(name: NotifyJoinGroup,
                                        object: from,
                                        userInfo: [NotiKey_group: groupId!, NotiKey_newList: newIdList!])
        
        print("join new group from: \(String(describing: from))")
    }

    func kickOutUser(_ from: String?, groupId: String?, kickId: String?) throws {
        let account = Wallet.shared.Addr!
        
        guard let group = GroupItem.cache[groupId!] else {
            return
        }
        
        if group.owner != account {
            print("This group is not mine")
            return
        }
        
        try GroupItem.KickOutUserNoti(group: group, kickIds: kickId, from: from!)
        
        print("someone kicked out")
    }

    func quitGroup(_ from: String?, groupId: String?, quitId: String?) throws {
        
        try GroupItem.QuitGroupNoti(from: from, groupId: groupId!, quitId: quitId!)
    }

    func syncGroup(_ groupId: String?) -> String {
        
        return GroupItem.SyncGroupFromMe(by: groupId!)
    }

    func syncGroupAck(_ groupId: String?, groupName: String?, owner: String?, banTalking: Bool, memberIdList: String?, memberNickNameList: String?) throws {
        
        let account = Wallet.shared.Addr!
        
        var group = GroupItem.cache[groupId!]
        if group == nil {
            group = GroupItem.init()
        }
        
        group!.gid = groupId
        group!.groupName = groupName
        group!.memberIds = memberIdList?.toArray()
        group!.memberNicks = memberNickNameList?.toArray()
        group!.banTalked = banTalking
        group!.leader = owner
        group!.owner = account
        
        if let err = GroupItem.UpdateGroup(group!) {
            print("sync group ack update error.\(String(describing: err.localizedDescription))")
        }
        
        print("sync group ack")
    }

}
