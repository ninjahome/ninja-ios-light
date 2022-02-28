//
//  FileManager+Extension.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/10.
//

import Foundation
import UIKit

extension FileManager {
        static var fileManager: FileManager {
                return FileManager.default
        }
        
        static func TmpDirectory() -> URL {
                let url = fileManager.temporaryDirectory.appendingPathComponent(njFileFolder, isDirectory: true)
                if fileManager.fileExists(atPath: url.path) {
                        return url
                }
                do {
                        try fileManager.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
                }catch let err{
                        print("------>>>", err)
                        return fileManager.temporaryDirectory
                }
                return url
        }
        
        static func cleanupTmpDirectory(){
                let tmpPath = TmpDirectory()
                do{
                        let tmpDirectory = try fileManager.contentsOfDirectory(atPath: tmpPath.path)
                        for path in tmpDirectory {
                                let filePath = tmpPath.appendingPathComponent(path)
                                print("------>cleaning file:=>", filePath)
                                try fileManager.removeItem(at: filePath)
                        }
                }catch let err{
                        print("------>clean up temporary directory err:=>", err)
                }
        }
        static func removeTmpDirectoryExpire(){
                
                let ttl = MessageItem.MaxMsgLiftTime
                let tmpPath = TmpDirectory()
                do{
                        let tmpDirectory = try fileManager.contentsOfDirectory(atPath: tmpPath.path)
                        for path in tmpDirectory {
                                let filePath = tmpPath.appendingPathComponent(path)
                                let attrs = try fileManager.attributesOfItem(atPath: filePath.path)
                                guard let createDate = attrs[.creationDate] as? Date else{
                                        continue
                                }
                                let now = (Date().timeIntervalSince1970)
                                let create = createDate.timeIntervalSince1970
                                let limitTime = now - create
                                guard ttl < limitTime else{
                                        continue
                                }
                                print("------>prepare to remove expire file:=>", filePath)
                                try fileManager.removeItem(at: filePath)
                        }
                        
                }catch let err{
                        print("------>clean up temporary directory err:=>", err)
                }
        }
        
        static func urlOfHash(has:String)->URL?{
                let filePath = TmpDirectory().appendingPathComponent(has)
                if fileManager.fileExists(atPath: filePath.path){
                        return filePath
                }
                return nil
        }
        
        static func writeByHash(has:String, content:Data)-> URL?{
                let tmpPath = TmpDirectory()
                let filePath = tmpPath.appendingPathComponent(has)
                if fileManager.fileExists(atPath: filePath.path){
                        return filePath
                }
                
                guard fileManager.createFile(atPath: filePath.path, contents: content, attributes: .none) else{
                        return nil
                }
                
                return filePath
        }
        
        static func readByHash(has:String) -> Data?{
                let tmpPath = TmpDirectory()
                let filePath = tmpPath.appendingPathComponent(has)
                if !fileManager.fileExists(atPath: filePath.path){
                        return nil
                }
                return fileManager.contents(atPath: filePath.path)
        }
        
        
        @discardableResult
        static func createFolder(_ folderName :String) -> URL {
                let folder = TmpDirectory().appendingPathComponent(folderName)
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: folder.absoluteString) {
                        do {
                                try fileManager.createDirectory(atPath: folder.path, withIntermediateDirectories: true, attributes: nil)
                                return folder
                        } catch let error as NSError {
                                print("\(error.description)")
                        }
                }
                return folder
        }
        
        static func writeFile(content: Data, path: URL) -> URL? {
                let success = fileManager.createFile(atPath: path.path, contents: content, attributes: .none)
                if success {
                        return path
                }
                return nil
        }
        
        static func readFile(url: URL) -> Data? {
                let fileContents = fileManager.contents(atPath: url.path)
                if fileContents?.isEmpty == false {
                        return fileContents
                } else {
                        return nil
                }
        }
        
        static func deleteFilesWithPath(_ path: String) {
                let fileManager = FileManager.default
                do {
                        let files = try fileManager.contentsOfDirectory(atPath: path)
                        let recordings = files.filter( { (name: String) -> Bool in
                                return name.hasSuffix(kAudioFileTypeWav)
                        })
                        for i in 0 ..< recordings.count {
                                let path = path + "/" + recordings[i]
                                print("removing \(path)")
                                do {
                                        try fileManager.removeItem(atPath: path)
                                } catch let error as NSError {
                                        print("could not remove \(path)")
                                        print("\(error.description)")
                                }
                        }
                } catch let error as NSError {
                        print("could not get contents of directory at \(path)")
                        print("\(error.description)")
                }
        }
        
        static func copyFile(fileName: String, origin: URL, to: URL) throws {
                //                let origin = from.appendingPathComponent(fileName)
                let direct = to
                return try fileManager.copyItem(at: origin, to: direct)
        }
        
        static func createURL(name: String) -> URL {
                let dir = FileManager.createFolder(njFileFolder)
                return dir.appendingPathComponent(name)
        }
        
        static func judgeFileOrFolderExists(filePath: String) -> Bool {
                let exist = fileManager.fileExists(atPath: filePath)
                guard exist else {
                        return false
                }
                return true
        }
        
        fileprivate static func covertUInt64ToString(with size: UInt64) -> String {
                var convertedValue: Double = Double(size)
                var multiplyFactor = 0
                let tokens = ["bytes", "KB", "MB", "GB", "TB", "PB",  "EB",  "ZB", "YB"]
                while convertedValue > 1024 {
                        convertedValue /= 1024
                        multiplyFactor += 1
                }
                return String(format: "%4.2f %@", convertedValue, tokens[multiplyFactor])
        }
        
}
