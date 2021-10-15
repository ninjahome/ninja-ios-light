//
//  CliMessage.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
//import SwiftyJSON


enum CMT:Int {
    case plainTxt = 0
    case image = 1
    case voice = 2
    case location = 3
    case video = 4
    case contact = 5
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
    var groupId:String?
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
    }

    init(to: String, audioD: Data, length: Int, groupId: String? = nil) {
        self.to = to
        self.type = .voice
        
        let audio = audioMsg.init()
        audio.content = audioD
        audio.duration = length
        self.audioData = audio
        self.groupId = groupId
    }
    
    init(to: String, imgData:Data, groupId: String? = nil) {
        self.to = to
        self.type = .image
        self.imgData = imgData
        self.groupId = groupId
    }

    init(to: String, locationData: locationMsg, groupId: String? = nil) {
        self.to = to
        self.type = .location
        self.locationData = locationData
        self.groupId = groupId
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
    }

}
