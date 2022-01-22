//
//  MsgViewController+MapView.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/7.
//

import Foundation
import UIKit

extension MsgViewController: MapViewControllerDelegate {
        func sendLocation(location: locationMsg) {
                print("send location msg:\(location.la)\(location.lo)\(location.str)")
                let cliMsg = CliMessage.init()
                if IS_GROUP {
                        cliMsg.groupId = peerUid
                        cliMsg.to = peerUid
                        cliMsg.locationData = location

                } else {
                        cliMsg.to = peerUid
                        cliMsg.locationData = location
                }
                cliMsg.type = .location

                sendAllTypeMessage(cliMsg)

        }
}
