//
//  VideoFileManager.swift
//  immeta
//
//  Created by 郭晓芙 on 2021/12/13.
//

import Foundation
import UIKit
import AVFoundation
import ChatLib
import Photos

class VideoFileManager {
        private static let trimPrefix = "trim."
        private static let hashSuffix = "mov"
        
        static func thumbnailImageOfVideoInVideoURL(videoURL: URL) -> (Data?, Bool) {
                let asset = AVURLAsset(url: videoURL as URL, options: nil)
                
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                do { 
                        let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                        let thumbnail = UIImage(cgImage: cgImage)
                        var thumbData = thumbnail.jpegData(compressionQuality: 1.0)!
                        if thumbData.count > ChatLibBigMsgThreshold(){
                                var err:NSError?
                                if let compressedThumb = ChatLibCompressImg(thumbData, Int32(ChatLibBigMsgThreshold()), &err){
                                        thumbData = compressedThumb
                                }
                        }
                        return (thumbData, cgImage.width > cgImage.height)
                        
                } catch let err{
                        print("------>>>", err.localizedDescription, videoURL.path)
                        return (nil, false)
                }
        }
        
        static func getVideoSize(videoURL: URL) -> Int {
                if let videoD = FileManager.readFile(url: videoURL) {
                        return videoD.count
                }
                return 0
        }
        
        static func readVideoData(videoURL: URL) -> Data? {
                if let data = FileManager.readFile(url: videoURL) {
                        return data
                }
                return nil
        }
        
        static func createVideoURL(name: String) -> URL {
                let dir = FileManager.createFolder(njFileFolder)
                return dir.appendingPathComponent(name)
        }
        
        static func compressVideo(from:Int, to:Int, videoURL: URL, callback:@escaping  ((_ status:AVAssetExportSession.Status, _ url:URL)->())){
                
                let asset = AVAsset(url: videoURL)
               
                let videoFinalPath = FileManager.TmpDirectory().appendingPathComponent(trimPrefix + videoURL.lastPathComponent)
                
                if FileManager.fileManager.fileExists(atPath: videoFinalPath.path){
                        callback(.completed, videoFinalPath)
                        return
                }
                
                let exporter :AVAssetExportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
                exporter.outputURL = videoFinalPath
                exporter.outputFileType = AVFileType.mov
                exporter.fileLengthLimit = Int64(to*95/100)
                
                exporter.exportAsynchronously {
                        callback(exporter.status, videoFinalPath)
                }
        }
        
        static func urlOfHash(has:String)->URL?{
                let filePath = FileManager.TmpDirectory().appendingPathComponent(has).appendingPathExtension(hashSuffix)
                if FileManager.fileManager.fileExists(atPath: filePath.path){
                        return filePath
                }
                return nil
        }
        
        static func writeByHash(has:String, content:Data)-> URL?{
                let tmpPath = FileManager.TmpDirectory()
                let filePath = tmpPath.appendingPathComponent(has).appendingPathExtension(hashSuffix)
                if FileManager.fileManager.fileExists(atPath: filePath.path){
                        return filePath
                }
                
                guard FileManager.fileManager.createFile(atPath: filePath.path, contents: content, attributes: .none) else{
                        return nil
                }
                
                return filePath
        }
}
