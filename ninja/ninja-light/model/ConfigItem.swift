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
        
        public static func initEndPoint(_ endPoint: String) -> ConfigItem {
                let item = ConfigItem.init()
                item.endPoint = endPoint
                return item
        }

        public static func loadEndPoint() -> String? {
                if let endPoint = ConfigItem.shared.endPoint {
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

        public static func updateEndPoint(_ item: ConfigItem) -> NJError? {
                do {
                        try CDManager.shared.UpdateOrAddOne(entity: "CDConfig", m: item, predicate: nil)
                } catch let err {
                        return NJError.config(err.localizedDescription)
                }
                return nil
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
