//
//  ConfigItem.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/12/1.
//

import Foundation
import CoreData

class ConfigItem: NSObject {
    public static let shared = ConfigItem()
    var obj: CDConfig?
    var endPoint: String?
    
    func loadEndPoint() -> String? {
        if let endPoint = self.endPoint {
            return endPoint
        }
        var inst: ConfigItem?
        do {
            inst = try CDManager.shared.GetOne(entity: "CDConfig", predicate: nil)
        } catch {
            return nil
        }
        
        return inst?.endPoint
    }
    
}

extension ConfigItem: ModelObj {
    func fullFillObj(obj: NSManagedObject) throws {
        guard let cObj = obj as? CDConfig else {
            throw NJError.coreData("Cast to CDConfig failed")
        }
        cObj.endPoint = self.endPoint
        self.obj = cObj
    }
    
    func initByObj(obj: NSManagedObject) throws {
        guard let cObj = obj as? CDConfig else {
            throw NJError.coreData("Cast to CDConfig failed")
        }
        self.endPoint = cObj.endPoint
        self.obj = cObj
    }
}
