//
//  CliMessage.swift
//  immeta
//
//  Created by wesley on 2021/4/7.
//

import Foundation
import ChatLib
import UIKit


enum CMT: Int {
        case plainTxt = 1
        case image = 2
        case voice = 3
        case location = 4
        case file = 5
        case videoWithHash = 11
        case redPacket = 22
        case contact = 23
        case unknown = -1
}

enum FileTyp: Int32{
        case video = 0
        case pdf = 1
        case word = 2
        case unsupport = -1
}


class txtMsg:IMPayLoad{
        
        var txt:String = ""
       
        init(txt:String){
                self.txt = txt
        }
        init(data:Data){
                txt =  String(data: data, encoding: .utf8) ?? ""
        }
        
        func wrappedToProto() -> Data? {
                guard !txt.isEmpty else{
                        return nil
                }
                var err:NSError?
                let data = ChatLibWrapTxtV2(txt, &err)
                if let e = err{
                        print("------>>>wrap txt to proto err:[\(e.localizedDescription)]")
                        return nil
                }
                return data
        }
}

class imgMsg: IMPayLoad{
        var has:String = ""
        var content: Data = Data()
        var key:Data?
       
        
        init(data:Data, has:String = "", key:Data? = nil){
                content = data
                self.has = has
                self.key = key
        }
             
        func wrappedToProto() -> Data? {
                guard content.count > 0 else{
                        return nil
                }
                var err:NSError?
                let data = ChatLibWrapImgV3(self.content, self.key, self.has, &err)
                if let e = err{
                        print("------>>>wrap img to proto err:[\(e.localizedDescription)]")
                        return nil
                }
                
                return data
        }
}


class audioMsg: IMPayLoad {
        
        var content: Data = Data()
        var duration: Int = 0
       
        init(data:Data, len:Int){
                content = data
                duration = len
        }
        
        func success(_ l: Int32, d: Data?) {
                self.duration = Int(l)
                self.content = d ?? Data()
        }
        
        
        func wrappedToProto() -> Data? {
                guard content.count > 0 else{
                        return nil
                }
                var err:NSError?
                let data = ChatLibWrapVoiceV2(Int32(duration), content, &err)
                if let e = err{
                        print("------>>>wrap audio to proto err:[\(e.localizedDescription)]")
                        return nil
                }
                
                return data
        }
}

class locationMsg: IMPayLoad {
        
        var lo: Float = 0
        var la: Float = 0
        var str: String = ""
        
        init(){
                
        }
        func wrappedToProto() -> Data? {
                var err:NSError?
                let data = ChatLibWrapLocationV2(str, Double(lo), Double(la), &err)
                if let e = err{
                        print("------>>>wrap location to proto err:[\(e.localizedDescription)]")
                        return nil
                }
                
                return data
        }
        
        init(name: String?, long: Double, lat: Double) {
                self.str = name ?? ""
                self.lo = Float(long)
                self.la = Float(lat)
        }
}


//class fileMsg: IMPayLoad {
//
//        static var supportsSecureCoding: Bool = true
//        var content: Data = Data()
//        var name: String = ""
//        var typ: FileTyp = .video
//
//        func encode(with coder: NSCoder) {
//                coder.encode(typ.rawValue, forKey: "typ")
//                coder.encode(name, forKey: "name")
//                coder.encode(content, forKey: "content")
//        }
//
//        required init?(coder: NSCoder) {
//                self.typ = FileTyp(rawValue: coder.decodeInt32(forKey:  "typ")) ?? .video
//                self.name = coder.decodeObject(of: NSString.self, forKey: "name") as? String ?? ""
//                self.content = coder.decodeObject(of: NSData.self, forKey: "content") as? Data ?? Data()
//        }
//
//        public func wrappedToProto() -> Data? {
//                guard content.count > 0 else{
//                        return nil
//                }
//                var err:NSError?
//                let data = ChatLibWrapFileV2(name, typ.rawValue, content, &err)
//                if let e = err{
//                        print("------>>>wrap file to proto err:[\(e.localizedDescription)]")
//                        return nil
//                }
//
//                return data
//        }
//
//        init(name:String?, data:Data?, typ:FileTyp = .video){
//                self.name = name ?? ""
//                self.typ = typ
//                self.content = data ?? Data()
//        }
//}
//
//class videoMsg:fileMsg{
//        var thumbnailImg: UIImage = defaultAvatar
//        private var tmpFileURL:URL?
//        
//        override func encode(with coder: NSCoder) {
//                super.encode(with: coder)
//                coder.encode(thumbnailImg, forKey: "thumbnailImg")
//                coder.encode(tmpFileURL, forKey: "tmpFileURL")
//        }
//        required init?(coder: NSCoder) {
//                super.init(coder: coder)
//                if let img = coder.decodeObject(of:UIImage.self, forKey: "thumbnailImg"){
//                        self.thumbnailImg = img
//                }
//                self.tmpFileURL = coder.decodeObject(of:NSURL.self, forKey: "tmpFileURL") as? URL
//        }
//        
//        init(name:String?, data:Data?, thumb:Data?){
//                super.init(name: name, data: data)
//                guard let d = thumb else{
//                        return
//                }
//                self.thumbnailImg = UIImage(data: d) ?? defaultAvatar
//        }
//        
//        init(name:String?, data:Data?){
//                super.init(name: name, data: data)
//                guard  let url = tmpUrl() else{
//                        return
//                }
//                let (img, _) = VideoFileManager.thumbnailImageOfVideoInVideoURL(videoURL: url)
//                if let d = img{
//                        self.thumbnailImg = UIImage(data: d)!
//                }
//        }
//        
//        func tmpUrl()->URL?{
//                if let url = self.tmpFileURL{
//                        if FileManager.judgeFileOrFolderExists(filePath:  url.path) {
//                                return tmpFileURL
//                        }
//                }
//                
//                tmpFileURL = FileManager.TmpDirectory().appendingPathComponent(self.name)
//                guard let u = tmpFileURL else{
//                        return nil
//                }
//                if FileManager.judgeFileOrFolderExists(filePath:  u.path) {
//                        return tmpFileURL
//                }
//                do {
//                        try self.content.write(to: u, options: [.atomic])
//                        return tmpFileURL
//                }catch let err{
//                        print("------>>> write video file failed", err)
//                        return nil
//                }
//        }
//}
//

class videoMsgWithHash: IMPayLoad {
        
        var thumbData:Data?
        var has:String?
        var isHorizon:Bool = false
        var key:Data? = nil
        
        init(thumb:Data, has:String, isHorizon:Bool = false, key:Data? = nil){
                self.thumbData = thumb
                self.has = has
                self.isHorizon = isHorizon
                self.key = key
        }
        
        func wrappedToProto() -> Data? {
                var err:NSError?
                let data = ChatLibWrapVideoV3(thumbData, key, has, isHorizon, &err)
                if let e = err{
                        print("------>>>wrap video to proto err:[\(e.localizedDescription)]")
                        return nil
                }
                
                return data
        }
}

class contactMsg: IMPayLoad {
        var uid:String=""
        var recommendor:String?
    
        init(uid:String, recommendor:String? = nil){
                self.uid = uid
                self.recommendor = recommendor
        }
        
        func wrappedToProto() -> Data? {
                var err:NSError?
                let data = ChatLibWrapContact(self.uid, self.recommendor, &err)
                if let e = err{
                        print("------>>>wrap contact to proto err:[\(e.localizedDescription)]")
                        return nil
                }
                
                return data
        }
}
class redPacketMsg:IMPayLoad {
        
        
        var from:String=""
        var to:String=""
        var amount:Int64 = 0
        
        init(from:String, to:String, amount:Int64){
                self.from = from
                self.to = to
                self.amount = amount
        }
        
        func wrappedToProto() -> Data? {
                var err:NSError?
                let data = ChatLibWrapRedPacket(from, to, amount, &err)
                if let e = err{
                        print("------>>>wrap redpacket to proto err:[\(e.localizedDescription)]")
                        return nil
                }
                
                return data
        }
}
