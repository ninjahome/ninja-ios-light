//
//  Constants.swift
//  ninja-light
//
//  Created by hyperorchid on 2021/4/8.
//

import Foundation
import UIKit

let NotifyContactChanged = NSNotification.Name(rawValue:"contact_new_changed")

let NotifyMessageAdded = NSNotification.Name(rawValue:"messsage_content_added")
let NotifyMessageSendResult = NSNotification.Name(rawValue:"messsage_send_result")
let NotifyMsgSumChanged = NSNotification.Name(rawValue:"messsage_sum_changed")

let NotifyWebsocketOffline = NSNotification.Name(rawValue:"websocket_status_offline")
let NotifyWebsocketOnline = NSNotification.Name(rawValue:"websocket_status_online")
let NotifyOnlineError = NSNotification.Name(rawValue: "websocket_online_error")


let NotifyGroupChanged = NSNotification.Name(rawValue: "group_meta_changed")
let NotifyJoinGroup = NSNotification.Name(rawValue: "add_new_member_to_group")
let NotifyKickOutGroup = NSNotification.Name(rawValue: "kick_out_member_from_group")
let NotifyKickMeOutGroup = NSNotification.Name(rawValue: "kick_me_out_member_from_group")


let NotifyGroupNameOrAvatarChanged = NSNotification.Name(rawValue: "group_avatar_changed")
let NotifyGroupMemberChanged = NSNotification.Name(rawValue: "group_member_changed")
let NotifyGroupDeleteChanged = NSNotification.Name(rawValue: "group_delete_changed")
let NotifyGroupCreated = NSNotification.Name(rawValue: "group_created_noti")

let dateFormatterGet = DateFormatter()

let kAudioFileTypeWav = "wav"
let kAudioFileTypeAmr = "amr"
let kAmrRecordFolder = "ChatAudioAmrRecord"
let kWavRecordFolder = "ChatAudioWavRecord"

let njFileFolder = "NJChatFiles"

let AvatarColors: [String] = ["F4CCE3", "D6CCF4", "BACEF0",
                    "ABDDEE", "CBEEA8", "BAF1E6",
                    "FAE5A6", "F0B5B2", "ACEFBA",
                    "BAD4EE", "EBEFAE", "F2C2B4",
                    "D8D8D8"]

let AppVersionKey = "APP_VERSION_IN_BUNDLE"

let MaxMembersInGroup = 50

public let defaultAvatar = UIImage(named: "logo_img")!
public let defaultAvatarData = UIImage(named: "logo_img")!.jpegData(compressionQuality: 1)!
public let nilAvatar = "1".data(using: .utf8)
public let nilAvatarLen = nilAvatar?.count
