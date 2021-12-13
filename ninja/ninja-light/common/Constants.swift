//
//  Constants.swift
//  ninja-light
//
//  Created by hyperorchid on 2021/4/8.
//

import Foundation

let NotifyContactChanged = NSNotification.Name(rawValue:"contact_new_changed")
let NotifyMessageAdded = NSNotification.Name(rawValue:"messsage_content_added")
let NotifyMsgSumChanged = NSNotification.Name(rawValue:"messsage_sum_changed")
let NotifyWebsocketOffline = NSNotification.Name(rawValue:"websocket_status_offline")
let NotifyWebsocketOnline = NSNotification.Name(rawValue:"websocket_status_online")
let NotifyOnlineError = NSNotification.Name(rawValue: "websocket_online_error")
let NotifyJoinGroup = NSNotification.Name(rawValue: "add_new_member_to_group")
let NotifyKickOutGroup = NSNotification.Name(rawValue: "kick_out_member_from_group")
let NotifyKickMeOutGroup = NSNotification.Name(rawValue: "kick_me_out_member_from_group")

let dateFormatterGet = DateFormatter()

let kAudioFileTypeWav = "wav"
let kAudioFileTypeAmr = "amr"
let kAmrRecordFolder = "ChatAudioAmrRecord"
let kWavRecordFolder = "ChatAudioWavRecord"

let njVideoFolder = "NJChatVideo"
let njFileFolder = "NJChatFile"

//enum AvaColor:String {
//    case c0 = "#F4CCE3"
//    case c1 = "#D6CCF4"
//    case c2 = "#BACEF0"
//    case c3 = "#ABDDEE"
//    case c4 = "#CBEEA8"
//    case c5 = "#BAF1E6"
//    case c6 = "#FAE5A6"
//    case c7 = "#F0B5B2"
//    case c8 = "#ACEFBA"
//    case c9 = "#BAD4EE"
//    case c10 = "#EBEFAE"
//    case c11 = "#F2C2B4"
//    case c12 = "#D8D8D8"
//}

let AvatarColors: [String] = ["F4CCE3", "D6CCF4", "BACEF0",
                    "ABDDEE", "CBEEA8", "BAF1E6",
                    "FAE5A6", "F0B5B2", "ACEFBA",
                    "BAD4EE", "EBEFAE", "F2C2B4",
                    "D8D8D8"]

//let AvatarColors: [String] = ["#F4CCE3", "#D6CCF4", "#BACEF0",
//                    "#ABDDEE", "#CBEEA8", "#BAF1E6",
//                    "#FAE5A6", "#F0B5B2", "#ACEFBA",
//                    "#BAD4EE", "#EBEFAE", "#F2C2B4",
//                    "#D8D8D8"]
