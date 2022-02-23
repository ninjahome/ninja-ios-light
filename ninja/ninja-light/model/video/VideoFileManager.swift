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
        
        static func thumbnailImageOfVideoInVideoURL(videoURL: URL) -> (UIImage?, Bool) {
                let asset = AVURLAsset(url: videoURL as URL, options: nil)
                
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
                guard let cgImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil) else {
                        return (nil, false)
                }
                

                let thumbnail = UIImage(cgImage: cgImage)
                return (thumbnail, cgImage.width > cgImage.height)
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
                let videoFinalPath = FileManager.TmpDirectory().appendingPathComponent(videoURL.lastPathComponent)
                let exporter :AVAssetExportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
                exporter.outputURL = videoFinalPath
                exporter.outputFileType = AVFileType.mov
                exporter.timeRange = CMTimeRangeFromTimeToTime(start: CMTime.zero, end: endDuration)
                
                exporter.exportAsynchronously {
                        callback(exporter.status, videoFinalPath)
                }
        }
}
