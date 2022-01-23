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
        override init() {
                super.init()
        }
        
        public static func InitService() {
                ContactItem.LocalSavedContact()
                GroupItem.LocalSavedGroup()
                MessageItem.loadUnread()
                ChatItem.ReloadChatRoom()
                dateFormatterGet.timeStyle = .medium
        }
        
        public static func InitAPP() {
                
                let endPoint = ConfigItem.loadEndPoint() ?? ""
                let current = getAppVersion()
                let saved = getSavedAppVersion()
                
                if current != saved {
                        NSLog("----[Current Version]---\(current ?? "no current")----[Saved Version]---\(saved ?? "no saved")")
                        
                        //Tips::
                        let userDefault = UserDefaults.standard
                        userDefault.set(current, forKey: AppVersionKey)
                }
                // networkID 5: company 2: other
                ChatLibInitAPP(endPoint, "a3a5c09826a246d0bfbef8084b81df1f", WebsocketSrv.shared, 6)
        }
        public static func InitPushParam(deviceToken:String) {
                ChatLibSetPushParam(deviceToken, DevTypeIOS, Debug)
        }
        
        public static func MaxAvatarSize()->Int{
                return ChatLibMaxAvatarSize()
        }
}
