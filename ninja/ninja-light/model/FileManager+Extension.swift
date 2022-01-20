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
        
        static func CachesDirectory() -> URL {
                let cachesPath =  fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                return cachesPath
        }
        
//        static func TmpDirectory() -> URL {
//                let tmpDir = fileManager.urls(for: .itemReplacementDirectory, in: .userDomainMask)[0]
//                return tmpDir
//        }
        
        @discardableResult
        static func createFolder(_ folderName :String) -> URL {
                let folder = CachesDirectory().appendingPathComponent(folderName)
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
        
        static func writeFile(content: Data, folderPath: URL, fileName: String) -> URL? {
                let filePath = folderPath.appendingPathComponent(fileName)
                let success = fileManager.createFile(atPath: filePath.path, contents: content, attributes: .none)
                if success {
                        return filePath
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
