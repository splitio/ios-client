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
        sempaphore.wait()
        return CoreDataHelper(managedObjectContext: managedObjContext, persistentCoordinator: persistenceCoordinator)
    }
}
