//
//  CoreData.swift
//  ninja-light
//
//  Created by wesley on 2021/4/5.
//

import Foundation
import CoreData

protocol ModelObj:NSObject {
        func fullFillObj(obj:NSManagedObject) throws
        func initByObj(obj:NSManagedObject) throws
}

class CDManager:NSObject{
        
        public static let shared = CDManager()
        private override init(){
                super.init()
        }
        // MARK: - Core Data stack

        lazy var persistentContainer: NSPersistentContainer = {
            /*
             The persistent container for the application. This implementation
             creates and returns a container, having loaded the store for the
             application to it. This property is optional since there are legitimate
             error conditions that could cause the creation of the store to fail.
            */
            let container = NSPersistentContainer(name: "ninja")
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                     
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            return container
        }()

        // MARK: - Core Data Saving support

        func saveContext () {
            let context = persistentContainer.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                        print("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
}

extension CDManager{
        
        func Get<T>(entity:String, predicate:NSPredicate? = nil,
                    sort:[[String:Bool]]? = nil, limit:Int? = nil)throws ->[T] where T: ModelObj{
                let managedContext = persistentContainer.viewContext
                let fetchRequest =  NSFetchRequest<NSManagedObject>(entityName: entity)
                
                if let myPredicate = predicate {
                        fetchRequest.predicate = myPredicate
                }
                
                if let mySort = sort {
                        var sortArr :[NSSortDescriptor] = []
                        for sortCond in mySort {
                           for (k, v) in sortCond {
                               sortArr.append(
                                 NSSortDescriptor(
                                   key: k, ascending: v))
                           }
                        }

                        fetchRequest.sortDescriptors = sortArr
                }

                if let limitNumber = limit {
                        fetchRequest.fetchLimit = limitNumber
                }
                
                var result:[T] = []
                let objArr = try managedContext.fetch(fetchRequest)
                for obj in objArr {
                        let t = T.init()
                        try t.initByObj(obj:obj)
                        result.append(t)
                }
                return result
        }
        
        func GetOne<T>(entity:String, predicate:NSPredicate? = nil)throws -> T?  where T: ModelObj{
                var result:[T] = []
                result = try self.Get(entity: entity, predicate: predicate, sort: nil, limit: 1)
                if result.count == 0{
                        return nil
                }
                return result.first
        }
        
        func UpdateOrAddOne<T>(entity:String, m:T, predicate:NSPredicate? = nil)throws where T: ModelObj{
                
                let managedContext = persistentContainer.viewContext
                let fetchRequest =  NSFetchRequest<NSManagedObject>(entityName: entity)
                
                if let myPredicate = predicate {
                        fetchRequest.predicate = myPredicate
                }
                fetchRequest.fetchLimit = 1
                let objArr = try managedContext.fetch(fetchRequest)
                
                if objArr.count == 0 {
                        try self.AddEntity(entity: entity, m: m)
                        return
                }
                let object = objArr.first!
                try m.fullFillObj(obj: object)
                
                try managedContext.save()
        }
        
        func AddBatch<T>(entity:String, m:[T])throws where T: ModelObj{
                
                let managedContext = persistentContainer.viewContext
                let entity = NSEntityDescription.entity(forEntityName: entity,
                                               in: managedContext)!
                for mObj in m {
                        let object = NSManagedObject(entity: entity,
                                                     insertInto: managedContext)
                        try mObj.fullFillObj(obj: object)
                }
                
                try managedContext.save()
        }
        
        func AddEntity<T>(entity:String, m:T)throws where T: ModelObj{
                let managedContext = persistentContainer.viewContext
                  
                 
                let entity = NSEntityDescription.entity(forEntityName: entity,
                                               in: managedContext)!
                  
                let object = NSManagedObject(entity: entity,
                                             insertInto: managedContext)
               
                try m.fullFillObj(obj: object)
                
                try managedContext.save()
        }
        
        func Delete(entity:String, predicate:NSPredicate? = nil)throws{
                let managedContext = persistentContainer.viewContext
                let fetchRequest =  NSFetchRequest<NSManagedObject>(entityName: entity)
                
                if let myPredicate = predicate {
                        fetchRequest.predicate = myPredicate
                }
                let objArr = try managedContext.fetch(fetchRequest)
                for obj in objArr {
                        managedContext.delete(obj)
                }
                try managedContext.save()
        }
        
        func DeleteObj(obj:NSManagedObject) throws{
                let managedContext = persistentContainer.viewContext
                managedContext.delete(obj)
                try managedContext.save()
        }
}
