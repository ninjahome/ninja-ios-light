//
//  MessageItem.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import CoreData
//import SwiftyJSON
import ChatLib

typealias MessageList = [MessageItem]

enum sendingStatus: Int16 {
    case sent = 0
    case sending
    case faild
}

class MessageItem: NSObject {
        
    public static let NotiKey = "peerUid"
    var timeStamp:Int64 = 0
    var from:String?
    var to:String?
    var typ:CMT = .plainTxt
    var payload:Any?
    var isOut:Bool = false
    var groupId:String?
    var status: sendingStatus = .sent
    
    var avatarInfo: Avatar?
    
    public static var cache:[String: MessageList] = [:]
//    public static var cacheGroup: [String: MessageList] = [:]
    override init() {
        super.init()
    }
    
    public static func loadUnread(){
        guard let owner = Wallet.shared.Addr else {
            return
        }
        var result:[MessageItem]?
        result = try? CDManager.shared.Get(entity: "CDUnread",
                                           predicate: NSPredicate(format: "owner == %@", owner))
        guard let data = result else{
                return
        }
        cache.removeAll()
        
        for msg in data {
            
            var peerUid: String
            if let groupId = msg.groupId {
                peerUid = groupId
            } else {
                if msg.isOut {
                    peerUid = msg.to!
                }else{
                    peerUid = msg.from!
                }
            }
                        
            if cache[peerUid] == nil{
                cache[peerUid] = MessageList.init()
            }
            cache[peerUid]?.append(msg)
            
        }
        
    }
    
    public static func removeRead(_ uid:String){
        cache.removeValue(forKey: uid)
        let owner = Wallet.shared.Addr!
        try? CDManager.shared.Delete(entity: "CDUnread",
                                predicate: NSPredicate(format: "owner == %@ AND (from == %@ OR to == %@)",
                                                       owner, uid, uid))
    }

    public static func removeAllRead() {
        cache.removeAll()
        let owner = Wallet.shared.Addr!
        try? CDManager.shared.Delete(entity: "CDUnread",
                                predicate: NSPredicate(format: "owner == %@", owner))
        
    }
    
    func coinvertToLastMsg() -> String{
        switch self.typ {
            case .plainTxt:
//                        let time = Date.init(timeIntervalSince1970: TimeInterval(self.timeStamp))
//                    dateFormatterGet.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
//                        return dateFormatterGet.string(from: time)
                return "[Text Message]"
            case .voice:
                    return "[Voice Message]"
            case .video:
                    return "[Video Message]"
            case .location:
                    return "[Location]"
            case .contact:
                    return "[Contact]"
            case .image:
                    return "[Image]"
        }
    }
        
    init(cliMsg: CliMessage, from: String, time: Int64, out:Bool) {
        super.init()
        self.from = from
        self.timeStamp = time
        self.to = cliMsg.to
        self.typ = cliMsg.type
        self.groupId = cliMsg.groupId
    
        switch self.typ {
        case .plainTxt:
            self.payload = cliMsg.textData
        case .image:
            self.payload = cliMsg.imgData
        case .voice:
            self.payload = cliMsg.audioData
        case .location:
            self.payload = cliMsg.locationData
        default:
            print("init MESSAGE error: undefined type")
        }

        self.isOut = out
    }
    
    init(cliMsg: CliMessage) {
        let sender = Wallet.shared.Addr!
        self.from = sender
        
        if let groupid = cliMsg.groupId {
            self.to = groupid
        } else {
            self.to = cliMsg.to
        }

        self.typ = cliMsg.type
        self.timeStamp = cliMsg.timestamp ?? Int64(Date().timeIntervalSince1970)
        self.isOut = true
        self.groupId = cliMsg.groupId

        switch self.typ {
        case .plainTxt:
            self.payload = cliMsg.textData
        case .image:
            self.payload = cliMsg.imgData
        case .voice:
            self.payload = cliMsg.audioData
        case .location:
            self.payload = cliMsg.locationData
        default:
            print("init MESSAGE error: undefined type")
        }
        self.status = .sending
    }
    
    public static func addSentIM(cliMsg: CliMessage) -> MessageItem {
        
        let msg = MessageItem.init(cliMsg: cliMsg)
        if cache[msg.to!] == nil{
            cache[msg.to!] = []
        }
        cache[msg.to!]!.append(msg)
        
        try? CDManager.shared.AddEntity(entity: "CDUnread", m: msg)
        return msg
    }
    
    public static func resetSending(cliMsg: CliMessage, success: Bool) {
        let msg = MessageItem.init(cliMsg: cliMsg)
        
        if success {
            msg.status = .sent
        } else {
            msg.status = .faild
        }
        
        var peerUid: String?
        if let gid = msg.groupId {
            peerUid = gid
        } else {
            peerUid = msg.to
        }
        
//        func modifyMsgStatus(_ msgInList: inout MessageItem, _ msg: MessageItem) {
//            msgInList = msg
//        }
        
        if var msgs = MessageItem.cache[peerUid!] {
            for (index, item) in msgs.enumerated() {
                if item.timeStamp == msg.timeStamp {
//                    modifyMsgStatus(&msgs[index], msg)
                    msgs[index] = msg
                    break
                }
            }
            
            MessageItem.cache.updateValue(msgs, forKey: peerUid!)
            
            for item in msgs {
                print(item.status)
                print(item.typ)
            }
        }
        
    }
    
    public static func receivedIM(msg: MessageItem) {
        var peerUid: String
        
        if let groupId = msg.groupId {
            peerUid = groupId
        } else {
            peerUid = msg.from!
        }
        if cache[peerUid] == nil {
            cache[peerUid] = []
        }
        cache[peerUid]?.append(msg)
        cache[peerUid]?.sort(by: { (a, b) -> Bool in
            return a.timeStamp < b.timeStamp
        })
        
        try? CDManager.shared.AddEntity(entity: "CDUnread", m: msg)
        NotificationCenter.default.post(name:NotifyMessageAdded,
                                        object: self, userInfo:[NotiKey: peerUid])
    }
    
    public static func saveUnread(_ msg:[MessageItem])throws {
        try CDManager.shared.AddBatch(entity: "CDUnread", m: msg)
        loadUnread()
    }
}

extension MessageItem: ModelObj {
        
    func fullFillObj(obj: NSManagedObject) throws {
        guard let uObj = obj as? CDUnread else {
            throw NJError.coreData("cast to unread item obj failed")
        }
        let owner = Wallet.shared.Addr!
//        uObj.type = Int16(self.typ.rawValue)
        uObj.from = self.from
        uObj.isOut = self.isOut
        
        switch self.typ {
        case .plainTxt:
            uObj.message = self.payload as? String
        case .image:
            uObj.image = self.payload as? Data
        case .voice:
            uObj.media = self.payload as? NSObject
        case .location:
            uObj.media = self.payload as? NSObject
        default:
            print("full fill msg: no such type")
        }
//                uObj.message = self.payload as? String
        uObj.owner = owner
        uObj.to = self.to
        uObj.unixTime = self.timeStamp
        uObj.type = Int16(self.typ.rawValue)
//        uObj.status = self.status.rawValue
        uObj.groupId = self.groupId
    }
    
    func initByObj(obj: NSManagedObject) throws {
        guard let uObj = obj as? CDUnread else {
            throw NJError.coreData("cast to unread item obj failed")
        }
        self.typ = CMT(rawValue: Int(uObj.type))!
    
        self.from = uObj.from
        self.isOut = uObj.isOut
    
        switch self.typ {
        case .plainTxt:
            self.payload = uObj.message
        case .image:
            self.payload = uObj.image
        case .voice:
            self.payload = uObj.media as? audioMsg
        case .location:
            self.payload = uObj.media as? locationMsg
        default:
            print("init by msg obj: no such type")
        }
    
//                self.payload = uObj.message
        self.to = uObj.to
        self.timeStamp = uObj.unixTime
//        self.status = sendingStatus(rawValue: uObj.status) ?? .sent
        self.groupId = uObj.groupId
        
//        let color = ContactItem.GetAvatarColor(by: self.from!)
    }
    
}

extension MessageList {
        
    func toString() -> String {
            
        var str = ""
        for msg in self{
            switch msg.typ {
            case .plainTxt:
                if msg.isOut{
                        str += "[me]:"
                }
                str += "\(msg.payload!)\r\n"
            case .contact://TODO::
                str += "Contact TODO::\r\n"
            case .voice://TODO::
                str += "Voice TODO::\r\n"
            case .location://TODO::
                str += "Location TODO::\r\n"
            case .image:
                str += "Image TODO::\r\n"
            case .video:
                str += "Video TODO::\r\n"
            }
        }
        return str
    }
}
