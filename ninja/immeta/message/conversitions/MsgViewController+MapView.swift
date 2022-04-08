//
//  MsgViewController+MapView.swift
//  immeta
//
//  Created by 郭晓芙 on 2021/12/7.
//

import Foundation
import UIKit

extension MsgViewController: MapViewControllerDelegate {
        
        func sendLocation(location: locationMsg) {
                print("------>>>send location msg:\(location.la)\(location.lo)\(location.str)")
 
                var gid:String? = nil
                if IS_GROUP{
                        gid = self.peerUid
                }
                
                let msg = MessageItem.init(to: peerUid,
                                           data: location,
                                           typ: .location,
                                           gid: gid)
                
                sendMessage(msg: msg)
        }
}

