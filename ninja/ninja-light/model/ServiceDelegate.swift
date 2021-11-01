//
//  ServiceDelegate.swift
//  ninja-light
//
//  Created by wesley on 2021/4/6.
//

import Foundation
import ChatLib

class ServiceDelegate: NSObject {
    public static let workQueue = DispatchQueue.init(label: "Serivce Queue", qos: .utility)
    
    override init() {
        super.init()
    }
    
    public static func InitService() {
        _ = InitConfig()
        ContactItem.LocalSavedContact()
        GroupItem.LocalSavedGroup()
        MessageItem.loadUnread()
        ChatItem.ReloadChatRoom()
        dateFormatterGet.timeStyle = .medium
    }

    public static func InitConfig() ->Error?{
        var error:NSError? = nil
        
        ChatLib.ChatLibConfigApp("", WebsocketSrv.shared, WebsocketSrv.shared, Wallet.shared.deviceToken, 1, &error)
        return error
    }
    
}
