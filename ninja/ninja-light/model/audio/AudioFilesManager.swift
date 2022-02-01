//
//  AudioFilesManager.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/2.
//

import Foundation

class AudioFilesManager {
        
        @discardableResult
        class func amrPathWithName(_ fileName: String) -> URL {
                let filePath = self.amrFilesFolder.appendingPathComponent("\(fileName).\(kAudioFileTypeAmr)")
                return filePath
        }
        
        
        @discardableResult
        class func wavPathWithName(_ fileName: String) -> URL {
                let filePath = self.wavFilesFolder.appendingPathComponent("\(fileName).\(kAudioFileTypeWav)")
                return filePath
        }
        
        @discardableResult
        class func saveWavData(_ wavData: Data, fileName: String) -> URL? {
                let filePath = self.wavFilesFolder.appendingPathComponent("\(fileName).\(kAudioFileTypeWav)")
                let success = FileManager.default.createFile(atPath: filePath.path, contents: wavData, attributes: .none)
                if success {
                        return filePath
                }
                return nil
        }
        
        @discardableResult
        class func renameFile(_ originPath: URL, destinationPath: URL) -> Bool {
                do {
                        try FileManager.default.moveItem(atPath: originPath.path, toPath: destinationPath.path)
                        return true
                } catch let error as NSError {
                        print("\(error.description)")
                        return false
                }
        }
        
        @discardableResult
        class fileprivate func createAudioFolder(_ folderName :String) -> URL {
                let documentsDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                let folder = documentsDirectory.appendingPathComponent(folderName)
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
        
        fileprivate class var amrFilesFolder: URL {
                get { return self.createAudioFolder(kAmrRecordFolder)}
        }
        
        fileprivate class var wavFilesFolder: URL {
                get { return self.createAudioFolder(kWavRecordFolder)}
        }
        
        class func deleteAllRecordingFiles() {
                self.deleteFilesWithPath(self.amrFilesFolder.path)
                self.deleteFilesWithPath(self.wavFilesFolder.path)
        }
        
        fileprivate class func deleteFilesWithPath(_ path: String) {
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
}
