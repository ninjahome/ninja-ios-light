//
//  FileManager+Extension.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/10.
//

import Foundation

extension FileManager {
        func cleanTempFiles() {
                do {
                        let tmpDirURL = FileManager.default.temporaryDirectory
                        let tmpDirectory = try contentsOfDirectory(atPath: tmpDirURL.path)
                        try tmpDirectory.forEach { file in
                                let fileUrl = tmpDirURL.appendingPathComponent(file)
                                try removeItem(atPath: fileUrl.path)
                        }
                } catch let err as NSError {
                        print("clear temp files failed \(err.localizedDescription)")
                }
        }
        

}
