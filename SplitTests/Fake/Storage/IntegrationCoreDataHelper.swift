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

    static func get(databaseName: String) -> CoreDataHelper {
        let sempaphore = DispatchSemaphore(value: 0)
        guard let modelUrl = Bundle(for: CoreDataHelper.self).url(forResource: "split_cache",
                                                                                          withExtension: "momd") else {
                                                                                            print("e")
            fatalError("Error loading model from bundle")

        }
//        guard let modelUrl = Bundle.main.url(forResource: "dcmodel", withExtension: "momd") else {
//            fatalError("Error loading model from bundle")
//        }

        guard let modelFile = NSManagedObjectModel(contentsOf: modelUrl) else {
            fatalError("Error initializing mom from: \(modelUrl)")
        }

        let persistenceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: modelFile)

        let managedObjContext = NSManagedObjectContext(
            concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedObjContext.persistentStoreCoordinator = persistenceCoordinator

        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            fatalError("Unable to resolve document directory")
        }
        let databaseUrl = docURL.appendingPathComponent("\(databaseName).sqlite")
        do {
            try persistenceCoordinator.addPersistentStore(ofType: NSInMemoryStoreType,
                                                          configurationName: nil,
                                                          at: databaseUrl, options: nil)

            sempaphore.signal()
        } catch {
            fatalError("Error migrating store: \(error)")
        }
        sempaphore.wait()
        return CoreDataHelper(managedObjectContext: managedObjContext, persistentCoordinator: persistenceCoordinator)
    }
}
