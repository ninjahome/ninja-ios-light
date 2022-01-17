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
                cachedLicense = Wallet.shared.liceneseExpireTime
        }
    
        public static func InitAPP() {
                var endPoint: String?
                if let point = ConfigItem.shared.endPoint {
                        endPoint = point
                } else {
                        endPoint = "192.168.1.167:16666"
                }
                
                // networkID 5: company 2: other
                ChatLibInitAPP(endPoint, "a3a5c09826a246d0bfbef8084b81df1f", WebsocketSrv.shared, 2)

        }
        
        public static func GetLicense() {
//                ChatLib.ChatLibReloadLicense(cachedLicense)
        }
}
