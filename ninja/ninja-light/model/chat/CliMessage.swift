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
        case plainTxt = 1
        case image = 2
        case voice = 3
        case location = 4
        case video = 6
        case file = 5
        case contact = 7
        case unknown = -1
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
        
        func unwrapFromProto(data: Data) -> Error? {
                var err:NSError?
                self.txt = ChatLibUnwrapTxtV2(data, &err)
                if let e = err{
                        return e
                }
                
                return nil
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
        
        func unwrapFromProto(data: Data) -> Error? {
                var err:NSError?
                let data = ChatLibUnwrapImgV2(data, &err)
                if let e = err {
                        return e
                }
                guard let d = data else{
                        return NJError.msg("unwrap empty image data")
                }
                self.content = d
                return nil
        }
}


class audioMsg: NSObject, NSCoding, ChatLibVoiceCallbackProtocol, IMPayLoad {
        
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
        
        func unwrapFromProto(data:Data)->Error?{
                var err:NSError?
                ChatLibUnwrapVoiceV2(data, self, &err)
                if err != nil{
                        return err
                }
                return nil
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

class fileMsg: NSObject, NSCoding,IMPayLoad,ChatLibFileCallbackProtocol {
        
        
        var content: Data = Data()
        var name: String = ""
        var url: String = ""
        var thumbnailImg: Data = Data()
        
        func encode(with coder: NSCoder) {
                coder.encode(name, forKey: "name")
                coder.encode(url, forKey: "url")
                coder.encode(thumbnailImg, forKey: "thumbnailImg")
        }
        
        required init?(coder: NSCoder) {
                
                super.init()
                self.name = coder.decodeObject(forKey: "name") as! String
                self.url = (coder.decodeObject(forKey: "url") as? String) ?? ""
                self.thumbnailImg = (coder.decodeObject(forKey: "thumbnailImg") as? Data) ?? Data()
        }
        
        override init() {
                super.init()
        }
        
        func unwrapFromProto(data:Data)->Error?{
                var err:NSError?
                ChatLibUnwrapFileV2(data, self, &err)
                if err != nil{
                        return err
                }
                return nil
        }
        
        func wrappedToProto() -> Data? {
                guard content.count > 0 else{
                        return nil
                }
                var err:NSError?
                let data = ChatLibWrapFileV2(name, "", Int32(content.count), content, &err)
                if let e = err{
                        print("------>>>wrap file to proto err:[\(e.localizedDescription)]")
                        return nil
                }
                
                return data
        }
        
        func success(_ n: String?, s: String?, l: Int32, d: Data?) {
                self.name = n ?? ""
                self.content = d ?? Data()
        }
}

class locationMsg: NSObject, NSCoding,IMPayLoad,ChatLibLocationCallbackProtocol {
        
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
        
        func unwrapFromProto(data:Data)->Error?{
                var err:NSError?
                ChatLibUnwrapLocationV2(data, self, &err)
                if err != nil{
                        return err
                }
                return nil
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
        
        func success(_ n: String?, lo: Double, la: Double) {
                self.str = n ?? ""
                self.lo = Float(lo)
                self.la = Float(la)
        }
}

class CliMessage: NSObject {
        var to: String = ""
        var type:CMT = .plainTxt
        var textData: String?
        var audioData: audioMsg?
        var imgData: Data?
        var locationData: locationMsg?
        var videoData: fileMsg?
        var fileData: fileMsg?
        var groupId: String?
        var timestamp: Int64?
        var isRetrying:Bool = false
        
        override init() {
                super.init()
                self.timestamp = ChatLibNowInMilliSeconds()
        }
        
        init(to:String, txtData: String, groupId: String? = nil) {
                self.to = to
                self.type = .plainTxt
                self.textData = txtData
                self.groupId = groupId
                self.timestamp = ChatLibNowInMilliSeconds()
        }
        
        init(to: String, audioD: Data, length: Int, groupId: String? = nil) {
                self.to = to
                self.type = .voice
                
                let audio = audioMsg.init()
                audio.content = audioD
                audio.duration = length
                self.audioData = audio
                self.groupId = groupId
                self.timestamp = ChatLibNowInMilliSeconds()
        }
        
        init(to: String, imgData:Data, groupId: String? = nil) {
                self.to = to
                self.type = .image
                self.imgData = imgData
                self.groupId = groupId
                self.timestamp = ChatLibNowInMilliSeconds()
        }
        
        init(to: String, videoUrl: URL, groupId: String? = nil) {
                self.to = to
                self.type = .video
                
                let video = fileMsg.init()
                let name = videoUrl.lastPathComponent
                video.name = name
                video.url = videoUrl.path
                video.thumbnailImg = VideoFileManager.thumbnailImageOfVideoInVideoURL(videoURL: videoUrl)?.pngData() ?? Data()
                
                self.videoData = video
                self.groupId = groupId
                self.timestamp = ChatLibNowInMilliSeconds()
        }
        
        init(to: String, fileUrl: URL, groupId: String? = nil) {
                self.to = to
                self.type = .file
                
                let file = fileMsg.init()
                file.name = fileUrl.lastPathComponent
                file.url = fileUrl.path
                //                file.url = fileUrl
                
                self.fileData = file
                self.groupId = groupId
                self.timestamp = ChatLibNowInMilliSeconds()
        }
        
        init(to: String, locationData: locationMsg, groupId: String? = nil) {
                self.to = to
                self.type = .location
                self.locationData = locationData
                self.groupId = groupId
                self.timestamp = ChatLibNowInMilliSeconds()
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
                self.timestamp = ChatLibNowInMilliSeconds()
        }
        
        func PackData() -> (Data?) {
                var data:Data?
                
                switch self.type {
                case .plainTxt:
                        data = ChatLibWrapTxt(self.textData)
                case .image:
                        let compress = compressImage(self.imgData)
                        data = ChatLibWrapImg(compress)
                case .voice:
                        guard let audioData = self.audioData, audioData.duration >= 1 else { //TODO::  duration?
                                return nil
                        }
                        data = ChatLibWrapVoice(audioData.duration, audioData.content)
                case .location:
                        guard let locData =  self.locationData else {
                                //TODO::
                                return nil
                        }
                        data = ChatLibWrapLocation(locData.str, Double(locData.lo), Double(locData.la))
                        
                case .file:
                        let url = URL(fileURLWithPath: self.fileData!.url)
                        guard let fileD = FileManager.readFile(url: url) else {
                                return nil
                        }
                        let size = fileD.count
                        let suffix = url.pathExtension
                        let name = self.fileData?.name
                        data = ChatLibWrapFile(name, suffix, size, fileD)
                case .video:
                        let url = URL(fileURLWithPath: self.videoData!.url)
                        guard let videoD = VideoFileManager.readVideoData(videoURL: url) else {
                                return nil
                        }
                        
                        let size = VideoFileManager.getVideoSize(videoURL: url)
                        let suffix = url.pathExtension
                        let name = self.videoData?.name
                        data = ChatLibWrapFile(name, suffix, size, videoD)
                default:
                        return nil
                }
                
                return data
        }
        
}
