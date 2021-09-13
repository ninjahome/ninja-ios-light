//
//  CliMessage.swift
//  ninja-light
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import SwiftyJSON


enum CMT:Int {
    case plainTxt = 0
    case image = 1
    case voice = 2
    case location = 3
    case video = 4
    case contact = 5
}
//
//struct audioMsg:Codable {
//    var content: Data = Data()
//    var duration: Int = 0
//}

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

    override init() {
        super.init()
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
        
//        func ToNinjaPayload() throws -> Data {
//            var jObj:JSON = [:]
//            jObj["type"].int = self.type.rawValue
////                jObj["data"] = self.data
//            switch self.type {
//            case .plainTxt:
//                jObj["data"].string = self.textData
//            case .image:
//                jObj["data"] = JSON(self.imgData as Any)
//            case .voice:
//                jObj["data"] = JSON(self.audioData as Any)
//            case .location:
//                jObj["data"] = JSON(self.locationData as Any)
//            default:
//                break
//            }
//                return try jObj.rawData()
//        }
//        
//        static func FromNinjaPayload(_ data:Data, to:String)throws -> CliMessage {
//            let cliMsg = CliMessage.init()
//
//            let json = try JSON(data: data)
//            cliMsg.type = CMT(rawValue: json["type"].int!) ?? .plainTxt
//            cliMsg.to = to
//
//            switch cliMsg.type {
//            case .plainTxt:
//                cliMsg.textData = json["data"].string!
//            case .voice:
//                cliMsg.audioData!.content = try json["data"].rawData()
//            case .image:
//                cliMsg.imgData = try json["data"].rawData()
////            case .location:
////                cliMsg.locationData = try json["data"].rawData()
//            default:
//                break
//            }
//            return cliMsg
//        }
}
