//
//  ImageFilesManager.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/6/17.
//

import Foundation


class ImageFilesManager {
    
    @discardableResult
    class func renameFile(_ originPath: URL, destinationPath: URL) -> Bool {
        do {
            try FileManager.default.moveItem(atPath: originPath.path, toPath: destinationPath.path)
            return true
        } catch let error as NSError {
            print("error:\(error)")
            return false
        }
    }

    
}
