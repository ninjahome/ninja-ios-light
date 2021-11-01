//
//  LockCache.swift
//  ninja-light
//
//  Created by 郭晓芙 on 2021/10/22.
//

import Foundation

class LockCache<T> : NSObject {
    var rwLock = pthread_rwlock_t()
    var contents: [String: T] = [:]

    override init() {
        pthread_rwlock_init(&rwLock, nil)
    }
    
    deinit {
        pthread_rwlock_destroy(&rwLock)
    }

    func getValues() -> [T] {
        pthread_rwlock_rdlock(&rwLock)
        defer {
            pthread_rwlock_unlock(&rwLock)
        }

        return Array(contents.values)
    }

    func get(idStr: String) -> T? {

        pthread_rwlock_rdlock(&rwLock)
        defer {
            pthread_rwlock_unlock(&rwLock)
        }

        return contents[idStr]

    }

    func setOrAdd(idStr: String, item: T?) {

        pthread_rwlock_wrlock(&rwLock)
        defer {
            pthread_rwlock_unlock(&rwLock)
        }

        if let i = item {
            contents.updateValue(i, forKey: idStr)
        }

    }

    func delete(idStr: String) {

        pthread_rwlock_wrlock(&rwLock)
        defer {
            pthread_rwlock_unlock(&rwLock)
        }

        contents.removeValue(forKey: idStr)
    }

    func deleteAll() {

        pthread_rwlock_wrlock(&rwLock)
        defer {
            pthread_rwlock_unlock(&rwLock)
        }

        contents.removeAll(keepingCapacity: true)
    }

}
