//
//  CliMessage.swift
//  ninja-light
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
        case contact = 7
        case videoWithHash = 11
        case unknown = -1
}

enum FileTyp: Int32{
        case video = 0
        case pdf = 1
        case word = 2
        case unsupport = -1
}

class txtMsg:NSObject, NSCoding,IMPayLoad{
        
        var txt:String = ""
        override init() {
                super.init()
        }
        init(txt:String){
                super.init()
                self.txt = txt
        }
        init(data:Data){
                super.init()
                txt =  String(data: data, encoding: .utf8) ?? ""
        }
        
        func encode(with coder: NSCoder) {
                coder.encode(txt, forKey: "txt")
        }
        
        required init?(coder: NSCoder) {
                super.init()
                self.txt = coder.decodeObject(forKey: "txt") as! String
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

class imgMsg:NSObject, NSCoding,IMPayLoad{
        var has:String = ""
        var content: Data = Data()
        var key:Data?
        override init() {
                super.init()
        }
        
        init(data:Data, has:String = "", key:Data? = nil){
                super.init()
                content = data
                self.has = has
                self.key = key
        }
        
        func encode(with coder: NSCoder) {
                coder.encode(content, forKey: "content")
                coder.encode(has, forKey: "has")
                coder.encode(key, forKey: "key")
        }
        
        required init?(coder: NSCoder) {
                super.init()
                self.content = coder.decodeObject(forKey: "content") as! Data
                self.has = coder.decodeObject(forKey: "has") as? String ?? ""
                self.key = coder.decodeObject(forKey: "key") as? Data
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


class audioMsg: NSObject, NSCoding, IMPayLoad {
        
        var content: Data = Data()
        var duration: Int = 0
        
        func encode(with coder: NSCoder) {
                coder.encode(content, forKey: "content")
                coder.encode(duration, forKey: "duration")
        }
        
        required init?(coder: NSCoder) {
                super.init()
                self.content = coder.decodeObject(forKey: "content") as! Data
                self.duration = coder.decodeInteger(forKey: "duration")
        }
        
        override init() {
                super.init()
        }
        
        init(data:Data, len:Int){
                super.init()
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

class locationMsg: NSObject, NSCoding,IMPayLoad {
        
        var lo: Float = 0
        var la: Float = 0
        var str: String = ""
        
        func encode(with coder: NSCoder) {
                coder.encode(lo, forKey: "lo")
                coder.encode(la, forKey: "la")
                coder.encode(str, forKey: "str")
        }
        
        required init?(coder: NSCoder) {
                super.init()
                self.la = coder.decodeFloat(forKey: "la")
                self.lo = coder.decodeFloat(forKey: "lo")
                self.str = coder.decodeObject(forKey: "str") as! String
        }
        
        override init() {
                super.init()
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
                super.init()
                self.str = name ?? ""
                self.lo = Float(long)
                self.la = Float(lat)
        }
}


class fileMsg: NSObject, NSCoding,IMPayLoad {
        
        var content: Data = Data()
        var name: String = ""
        var typ: FileTyp = .video
        
        func encode(with coder: NSCoder) {
                coder.encode(typ.rawValue, forKey: "typ")
                coder.encode(name, forKey: "name")
                coder.encode(content, forKey: "content")
        }
        
        required init?(coder: NSCoder) {
                super.init()
                self.typ = FileTyp(rawValue: coder.decodeInt32(forKey:  "typ")) ?? .video
                self.name = coder.decodeObject(forKey: "name") as? String ?? ""
                self.content = coder.decodeObject(forKey: "content") as? Data ?? Data()
        }
        
        override init() {
                super.init()
        }
        
        public func wrappedToProto() -> Data? {
                guard content.count > 0 else{
                        return nil
                }
                var err:NSError?
                let data = ChatLibWrapFileV2(name, typ.rawValue, content, &err)
                if let e = err{
                        print("------>>>wrap file to proto err:[\(e.localizedDescription)]")
                        return nil
                }
                
                return data
        }
        
        init(name:String?, data:Data?, typ:FileTyp = .video){
                super.init()
                
                self.name = name ?? ""
                self.typ = typ
                self.content = data ?? Data()
        }
}

class videoMsg:fileMsg{
        var thumbnailImg: UIImage = defaultAvatar
        private var tmpFileURL:URL?
        
        override init() {
                super.init()
        }
        override func encode(with coder: NSCoder) {
                super.encode(with: coder)
                coder.encode(thumbnailImg, forKey: "thumbnailImg")
                coder.encode(tmpFileURL, forKey: "tmpFileURL")
        }
        required init?(coder: NSCoder) {
                super.init(coder: coder)
                if let img = coder.decodeObject(forKey: "thumbnailImg") as? UIImage{
                        self.thumbnailImg = img
                }
                self.tmpFileURL = coder.decodeObject(forKey: "tmpFileURL") as? URL
        }
        
        init(name:String?, data:Data?, thumb:UIImage?){
                super.init(name: name, data: data)
                self.thumbnailImg = thumb ?? defaultAvatar
        }
        
        init(name:String?, data:Data?){
                super.init(name: name, data: data)
                guard  let url = tmpUrl() else{
                        return
                }
                let (img, _) = VideoFileManager.thumbnailImageOfVideoInVideoURL(videoURL: url)
                if let d = img{
                        self.thumbnailImg = d
                }
        }
        
        func tmpUrl()->URL?{
                if let url = self.tmpFileURL{
                        if FileManager.judgeFileOrFolderExists(filePath:  url.path) {
                                return tmpFileURL
                        }
                }
                
                tmpFileURL = FileManager.TmpDirectory().appendingPathComponent(self.name)
                guard let u = tmpFileURL else{
                        return nil
                }
                if FileManager.judgeFileOrFolderExists(filePath:  u.path) {
                        return tmpFileURL
                }
                do {
                        try self.content.write(to: u, options: [.atomic])
                        return tmpFileURL
                }catch let err{
                        print("------>>> write video file failed", err)
                        return nil
                }
        }
}


class videoMsgWithHash: NSObject, NSCoding,IMPayLoad {
        var thumbData:Data?
        var has:String?
        var isHorizon:Bool = false
        var key:Data? = nil
        
        func encode(with coder: NSCoder) {
                coder.encode(thumbData, forKey: "thumb")
                coder.encode(has, forKey: "has")
                coder.encode(key, forKey: "key")
                coder.encode(isHorizon, forKey: "isHorizon")
        }
        
        required init?(coder: NSCoder) {
                super.init()
                self.thumbData = coder.decodeObject(forKey: "thumb") as? Data
                self.has = coder.decodeObject(forKey: "has") as? String
                self.isHorizon = coder.decodeBool(forKey: "isHorizon")
                self.key = coder.decodeObject(forKey: "key") as? Data
        }
        
        override init() {
                super.init()
        }
        
        init(thumb:Data, has:String, isHorizon:Bool = false, key:Data? = nil){
                super.init()
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
