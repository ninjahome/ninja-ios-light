//
//  ServiceDelegate.swift
//  ninja-light
//
//  Created by wesley on 2021/4/6.
//

import Foundation
import IosLib

class ServiceDelegate: NSObject {
        public static let workQueue = DispatchQueue.init(label: "Serivce Queue", qos: .utility)
        
        override init() {
                super.init()
        }
        
        public static func InitService(){
                //TODO:: more system configs
                IosLib.IosLibConfigApp("", WebsocketSrv.shared)
                ContactItem.LocalSavedContact()
                MessageItem.loadUnread()
                dateFormatterGet.timeStyle = .medium
        }
    
        public static func InitConfig() {
            IosLib.IosLibConfigApp("", WebsocketSrv.shared)
        }
    
}
