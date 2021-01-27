//
//  CoreDataHelperBuilder.swift
//  Split
//
//  Created by Javier L. Avrudsky on 27/01/2021.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

class CoreDataHelperBuilder {

    private static let kDataModelName = "split_cache"
    private static let kDataModelExtentsion = "momd"
    private static let kDatabaseExtension = "sqlite"

    static func build(databaseName: String, dispatchQueue: DispatchQueue) -> CoreDataHelper? {

        //let bundle = Bundle(for: type(of: self))
        let bundle = Bundle(for: CoreDataHelperBuilder.self)
        guard let modelUrl = bundle.url(forResource: kDataModelName, withExtension: kDataModelExtentsion) else {
            fatalError("Error loading model from bundle")
        }

        guard let modelFile = NSManagedObjectModel(contentsOf: modelUrl) else {
            fatalError("Error initializing mom from: \(modelUrl)")
        }

        let persistenceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: modelFile)
        var createdManagedObjContext: NSManagedObjectContext?
        // Managed object context should be created in some queue that operations run
        dispatchQueue.sync {
            createdManagedObjContext = NSManagedObjectContext(
                concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        }

        guard let managedObjContext = createdManagedObjContext else {
            fatalError("Could not create context for cache database")
        }

        managedObjContext.persistentStoreCoordinator = persistenceCoordinator

        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            fatalError("Unable to resolve document directory")
        }

        let databaseUrl = docURL.appendingPathComponent("\(databaseName).\(self.kDatabaseExtension)")
        do {
            try persistenceCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                          configurationName: nil,
                                                          at: databaseUrl, options: nil)

            return CoreDataHelper(managedObjectContext: managedObjContext,
                                  persistentCoordinator: persistenceCoordinator)

        } catch {
            return nil
        }
    }
}
