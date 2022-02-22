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
        case summary = 6
        case contact = 7
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
        
        var content: Data = Data()
        override init() {
                super.init()
        }
        
        init(data:Data){
                super.init()
                content = data
        }
        
        func encode(with coder: NSCoder) {
                coder.encode(content, forKey: "content")
        }
        
        required init?(coder: NSCoder) {
                super.init()
                self.content = coder.decodeObject(forKey: "content") as! Data
        }
        
        func wrappedToProto() -> Data? {
                guard content.count > 0 else{
                        return nil
                }
                var err:NSError?
                let data = ChatLibWrapImgV2(self.content, &err)
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

class sumMsg: NSObject, NSCoding, IMPayLoad {
        var content:Data = Data()
        var has:String = ""
        var mediaTyp:CMT = .image
        
        func encode(with coder: NSCoder) {
                coder.encode(content, forKey: "content")
                coder.encode(hash, forKey: "hash")
        }
        
        required init?(coder: NSCoder) {
                super.init()
                self.content = coder.decodeObject(forKey: "content") as! Data
                self.has = coder.decodeObject(forKey: "hash") as! String
        }
        
        override init() {
                super.init()
        }
        
        init(data:Data, hash:String){
                super.init()
                self.content = data
                self.has = hash
        }
        
        func success(_ h: String, d: Data?) {
                self.has = h
                self.content = d ?? Data()
        }
        
        func wrappedToProto() -> Data? {
                guard content.count > 0 else{
                        return nil
                }
                var err:NSError?
                let data = ChatLibWrapSummary(self.has,self.mediaTyp, content, &err)
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
        public static let defaultImg = UIImage(named: "logo_img")!
        var thumbnailImg: UIImage = defaultImg
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
                self.thumbnailImg = (coder.decodeObject(forKey: "thumbnailImg") as? UIImage) ?? videoMsg.defaultImg
                self.tmpFileURL = coder.decodeObject(forKey: "tmpFileURL") as? URL
        }
        
        init(name:String?, data:Data?, thumb:UIImage?){
                super.init(name: name, data: data)
                self.thumbnailImg = thumb ?? videoMsg.defaultImg
        }
        
        init(name:String?, data:Data?){
                super.init(name: name, data: data)
                guard  let url = tmpUrl() else{
                        return
                }
                self.thumbnailImg = VideoFileManager.thumbnailImageOfVideoInVideoURL(videoURL: url) ?? videoMsg.defaultImg
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
