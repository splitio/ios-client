//
//  IntegrationCoreDataHelper.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 16/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData
@testable import Split
import XCTest

struct CrudKey {
    static let insert = NSInsertedObjectsKey
    static let delete = NSDeletedObjectsKey
    static let update = NSUpdatedObjectsKey
}

class IntegrationCoreDataHelper  {

    static func get(databaseName: String, dispatchQueue: DispatchQueue) -> CoreDataHelper {
        let sempaphore = DispatchSemaphore(value: 0)
        guard let modelUrl = Bundle(for: CoreDataHelper.self).url(forResource: "split_cache",
                                                                  withExtension: "momd") else {
            fatalError("Error loading model from bundle")

        }

        guard let modelFile = NSManagedObjectModel(contentsOf: modelUrl) else {
            fatalError("Error initializing mom from: \(modelUrl)")
        }

        let persistenceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: modelFile)

        var ctx: NSManagedObjectContext?
        dispatchQueue.sync {
            ctx = NSManagedObjectContext(
                concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        }
        let managedObjContext = ctx!
        managedObjContext.persistentStoreCoordinator = persistenceCoordinator

        do {
            try persistenceCoordinator.addPersistentStore(ofType: NSInMemoryStoreType,
                                                          configurationName: nil,
                                                          at: nil, options: nil)
            sempaphore.signal()
        } catch {
            print("Error creating test database")
            sempaphore.signal()
        }
        if Thread.isMainThread { print("⚠️ BLOCKINGQUEUE .take() RUNNING ON MAIN ‼️") }
        sempaphore.wait()
        return CoreDataHelper(managedObjectContext: managedObjContext, persistentCoordinator: persistenceCoordinator)
    }

    static func observeChanges() {
        obsCrud.removeAll()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextObjectsDidChange(_:)),
                                               name: Notification.Name.NSManagedObjectContextObjectsDidChange,
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDidSave(_:)),
                                               name: Notification.Name.NSManagedObjectContextDidSave,
                                               object: nil)
    }

    static func stopObservingChanges() {
        NotificationCenter.default.removeObserver(self)
        obsCrud.removeAll()
    }

    @objc static func contextObjectsDidChange(_ notification: Notification) {

    }

    @objc static func contextDidSave(_ notification: Notification) {
        checkUpdatesAndFireExp(info: notification.userInfo)
    }

    static func checkUpdatesAndFireExp(info: [AnyHashable: Any]?) {
        guard let info = info else { return }
        let keys = [CrudKey.insert, CrudKey.update, CrudKey.delete]
        for key in keys {
            if let values = info[key] as? Set<NSManagedObject> {
                for value in values {
                    if let entityType = getEntityType(value) {
//                        print("ObsCrud processing key: \(key)")
                        let key = buildObsRowKey(entity: entityType, operation: key)
                        if var row = obsCrud[key] {
                            row.increaseCount()
                            if row.shouldTrigger() {
                                row.expectation.fulfill()
                                obsCrud.removeValue(forKey: key)
//                                print("ObsCrud triggered for: \(key)")
                            } else {
                                obsCrud[key] = row
//                                print("ObsCrud got : \(key) -> limit, curr: [\(row.triggerCount), \(row.currentCount)]")
                            }
                        }
                    }
                }
            }
        }
    }

    private static func getEntityType(_ entity: Any) -> CoreDataEntity? {
        if let _ = entity as? SplitEntity {
            return .split
        }

        if let _ = entity as? MySegmentEntity {
            return .mySegment
        }
        return nil
    }

    private struct DbRowNotification {
        let expectation: XCTestExpectation
        let triggerCount: Int
        var currentCount: Int = 0

        mutating func increaseCount() {
            currentCount+=1
        }

        func shouldTrigger() -> Bool {
            return triggerCount == currentCount
        }
    }

    private static var obsCrud = [String: DbRowNotification]()
    
    static func getDbExp(count: Int, entity: CoreDataEntity, operation: String) -> XCTestExpectation {
        let row = DbRowNotification(expectation: XCTestExpectation(description: "\(operation)_count: \(count)"), triggerCount: count)
        obsCrud[buildObsRowKey(entity: entity, operation: operation)] = row
        return row.expectation
    }

    static func buildObsRowKey(entity: CoreDataEntity, operation: String) -> String {
        return "\(entity.rawValue)_\(operation)"
    }
}
