//
//  VideoFileManager.swift
//  ninja-light
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
        
        static func thumbnailImageOfVideoInVideoURL(videoURL: URL) -> (UIImage?, Bool) {
                let asset = AVURLAsset(url: videoURL as URL, options: nil)
                
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                do { 
                        let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
                        let thumbnail = UIImage(cgImage: cgImage)
                        return (thumbnail, cgImage.width > cgImage.height)
                        
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
                let assetDuration = CMTimeGetSeconds(asset.duration)
                
                let end = assetDuration/Float64(from) * Float64(to) - 1
                
                let endDuration = CMTimeMakeWithSeconds(end, preferredTimescale: 1)
                let videoFinalPath = FileManager.TmpDirectory().appendingPathComponent(trimPrefix + videoURL.lastPathComponent)
                
                if FileManager.fileManager.fileExists(atPath: videoFinalPath.path){
                        callback(.completed, videoFinalPath)
                        return
                }
                
                let exporter :AVAssetExportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
                exporter.outputURL = videoFinalPath
                exporter.outputFileType = AVFileType.mov
                exporter.timeRange = CMTimeRangeFromTimeToTime(start: CMTime.zero, end: endDuration)
                
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
