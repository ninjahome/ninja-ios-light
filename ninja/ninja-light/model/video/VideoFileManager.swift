//
//  VideoFileManager.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/13.
//

import Foundation
import UIKit
import AVFoundation

class VideoFileManager {
        static func thumbnailImageOfVideoInVideoURL(videoURL: URL) -> UIImage? {
                let asset = AVURLAsset(url: videoURL as URL, options: nil)
                
                let imageGenerator = AVAssetImageGenerator(asset: asset)
                imageGenerator.appliesPreferredTrackTransform = true
//                let time = CMTimeMakeWithSeconds(0, preferredTimescale: 1)
//                var actualTime: CMTime = CMTimeMake(value: 0, timescale: 0)
                guard let cgImage = try? imageGenerator.copyCGImage(at: .zero, actualTime: nil) else {
                        return nil
                }

                let thumbnail = UIImage(cgImage: cgImage)
                return thumbnail
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

}
