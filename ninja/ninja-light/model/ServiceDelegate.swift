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
        public static let DevTypeIOS = 1
        public static let Debug = true
        public static var deviceToken:String?
        public static var cachedLicense:Int64 = 0
        override init() {
            super.init()
        }
    
        public static func InitService() {
            ContactItem.LocalSavedContact()
            GroupItem.LocalSavedGroup()
            MessageItem.loadUnread()
            ChatItem.ReloadChatRoom()
            dateFormatterGet.timeStyle = .medium

                cachedLicense = 0//TOOD::Load license from database
        }
    
        public static func InitAPP(){
            ChatLib.ChatLibInitAPP("192.168.1.167:16666", WebsocketSrv.shared, deviceToken, DevTypeIOS, Debug)
        }
        
        public static func GetLicense(){
                ChatLib.ChatLibReloadLicense(cachedLicense)
        }
}
