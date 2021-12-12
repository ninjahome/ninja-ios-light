//
//  CliMessage.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
//import SwiftyJSON
import ChatLib
import UIKit


enum CMT: Int {
        case plainTxt = 0
        case image = 1
        case voice = 2
        case location = 3
        case video = 4
        case contact = 5
        case file = 6
}

class audioMsg: NSObject, NSCoding {
        var content: Data = Data()
        var duration: Int = 0

        func encode(with coder: NSCoder) {
                coder.encode(content, forKey: "content")
                coder.encode(duration, forKey: "duration")
        }

        required init?(coder: NSCoder) {
                self.content = coder.decodeObject(forKey: "content") as! Data
                self.duration = coder.decodeInteger(forKey: "duration")
        }

        override init() {
                super.init()
        }

}

class videoMsg: NSObject, NSCoding {
        var content: Data = Data()
        var name: String = ""
        var url: URL?
        var thumbnailImg: UIImage?
        
        func encode(with coder: NSCoder) {
                coder.encode(content, forKey: "content")
                coder.encode(name, forKey: "name")
                coder.encode(url, forKey: "url")
                coder.encode(thumbnailImg, forKey: "thumbnailImg")
        }

        required init?(coder: NSCoder) {
                self.content = coder.decodeObject(forKey: "content") as! Data
                self.name = coder.decodeObject(forKey: "name") as! String
                self.url = coder.decodeObject(forKey: "url") as? URL
                self.thumbnailImg = coder.decodeObject(forKey: "thumbnailImg") as? UIImage
        }

        override init() {
                super.init()
        }
}

class locationMsg: NSObject, NSCoding {
    
        var lo: Float = 0
        var la: Float = 0
        var str: String = ""

        func encode(with coder: NSCoder) {
                coder.encode(lo, forKey: "lo")
                coder.encode(la, forKey: "la")
                coder.encode(str, forKey: "str")
        }

        required init?(coder: NSCoder) {
                self.la = coder.decodeFloat(forKey: "la")
                self.lo = coder.decodeFloat(forKey: "lo")
                self.str = coder.decodeObject(forKey: "str") as! String
        }

        override init() {
                super.init()
        }

}

class CliMessage: NSObject {
        var to: String?
        var type:CMT = .plainTxt
        var textData: String?
        var audioData: audioMsg?
        var imgData: Data?
        var locationData: locationMsg?
        var videoData: videoMsg?
        var groupId: String?
        var timestamp: Int64?

        override init() {
                super.init()
                self.timestamp = Int64(Date().timeIntervalSince1970)
        }

        init(to:String, txtData: String, groupId: String? = nil) {
                self.to = to
                self.type = .plainTxt
                self.textData = txtData
                self.groupId = groupId
                self.timestamp = Int64(Date().timeIntervalSince1970)
        }

        init(to: String, audioD: Data, length: Int, groupId: String? = nil) {
                self.to = to
                self.type = .voice

                let audio = audioMsg.init()
                audio.content = audioD
                audio.duration = length
                self.audioData = audio
                self.groupId = groupId
                self.timestamp = Int64(Date().timeIntervalSince1970)
        }

        init(to: String, imgData:Data, groupId: String? = nil) {
                self.to = to
                self.type = .image
                self.imgData = imgData
                self.groupId = groupId
                self.timestamp = Int64(Date().timeIntervalSince1970)
        }
        
        init(to: String, videoData: Data, videoUrl: URL, groupId: String? = nil) {
                self.to = to
                self.type = .video
                
                let video = videoMsg.init()
                let name = videoUrl.lastPathComponent
                video.content = videoData
                video.name = name
                video.url = videoUrl
                
                self.videoData = video
                self.groupId = groupId
                self.timestamp = Int64(Date().timeIntervalSince1970)
        }

        init(to: String, locationData: locationMsg, groupId: String? = nil) {
                self.to = to
                self.type = .location
                self.locationData = locationData
                self.groupId = groupId
                self.timestamp = Int64(Date().timeIntervalSince1970)
        }

        init(to: String, la: Float, lo: Float, describe: String, groupId: String? = nil) {
                self.to = to
                self.type = .location

                let loca = locationMsg.init()
                loca.la = la
                loca.lo = lo
                loca.str = describe

                self.locationData = loca
                self.groupId = groupId
                self.timestamp = Int64(Date().timeIntervalSince1970)
        }
        
        func PackData() -> (Data?) {
                var data:Data?
                var gid:String = ""
                var isGroup = false
                if let groupId = groupId {
                        isGroup = true
                        gid = groupId
                }
                
                switch self.type {
                case .plainTxt:
                        if isGroup {
                                data = ChatLib.ChatLibPackGroupTxt(gid, self.textData)
                        } else {
                                data = ChatLib.ChatLibPackPlainTxt(self.textData)
                        }
                case .image:
                        if isGroup {
                                data = ChatLib.ChatLibPackGroupImage(gid, self.imgData)
                        } else {
                                data = ChatLib.ChatLibPackImage(self.imgData)
                        }
                case .voice:
                        guard let audioData = self.audioData, audioData.duration > 1 else { //TODO::  duration?
                                //TODO::
                                return nil
                        }
                        if isGroup {
                                data = ChatLib.ChatLibPackGroupVoice(gid, audioData.content, audioData.duration)
                        } else {
                                data = ChatLib.ChatLibPackVoice(audioData.content, audioData.duration)
                        }
                    
                case .location:
                        guard let locData =  self.locationData else {
                                //TODO::
                                return nil
                        }
                        if isGroup {
                                data = ChatLib.ChatLibPackGroupLocation(gid,locData.str, locData.lo, locData.la)
                        } else {
                                data = ChatLib.ChatLibPackLocation(locData.lo, locData.la, locData.str)
                        }
                case .file:
                        //TODO::
                        return nil
                case .video:
                        guard let videoD = self.videoData?.content else {
                                return nil
                        }
                        let size = videoD.count
                        let name = self.videoData?.name
                        
                        if isGroup {
                                data = ChatLib.ChatLibPackGroupFile(gid, name, videoD, size)
                        } else {
                                data = ChatLib.ChatLibPackFile(videoD, size, name)
                        }
                default:
                        return nil
                }
                
                return data
        }

}
