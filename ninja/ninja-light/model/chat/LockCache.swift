//
//  LockCache.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/10/22.
//

import Foundation

class LockCache<T> : NSObject {
    let rlock = NSLock()
    let wlock = NSLock()
    
    var contents: [String: T] = [:]
    
    func getValues() -> [T] {
        
        rlock.lock()
        defer {
            rlock.unlock()
        }
        
        return Array(contents.values)
    }
    
    func get(idStr: String) -> T? {
        
        rlock.lock()
        defer {
            rlock.unlock()
        }
        
        return contents[idStr]
        
    }
    
    func setOrAdd(idStr: String, item: T?) {
        
        wlock.lock()
        defer {
            wlock.unlock()
        }
        
        if let i = item {
            contents.updateValue(i, forKey: idStr)
        }
        
    }
    
    func delete(idStr: String) {
        
        wlock.lock()
        defer {
            wlock.unlock()
        }
        
        contents.removeValue(forKey: idStr)
    }
    
    func deleteAll() {
        
        wlock.lock()
        defer {
            wlock.unlock()
        }
        
        contents.removeAll(keepingCapacity: true)
    }
    
}
