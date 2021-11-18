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
        InitConfig()
        ContactItem.LocalSavedContact()
        GroupItem.LocalSavedGroup()
        MessageItem.loadUnread()
        ChatItem.ReloadChatRoom()
        dateFormatterGet.timeStyle = .medium
    }

    public static func InitConfig(){
        ChatLib.ChatLibInitAPP("35.75.21.32", WebsocketSrv.shared, Wallet.shared.deviceToken, 1)
    }
    
}
