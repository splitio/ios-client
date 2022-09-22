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

    static func build(databaseName: String) -> CoreDataHelper? {

        let bundle = Bundle.split
        guard let modelUrl = bundle.url(forResource: kDataModelName, withExtension: kDataModelExtentsion) else {
            Logger.e("Error loading model from bundle")
            return nil
        }

        guard let modelFile = NSManagedObjectModel(contentsOf: modelUrl) else {
            Logger.e("Error initializing mom from: \(modelUrl)")
            return nil
        }

        let persistenceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: modelFile)

        let managedObjContext = NSManagedObjectContext(
            concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)

        managedObjContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        managedObjContext.persistentStoreCoordinator = persistenceCoordinator

        guard let docURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).last else {
            Logger.e("Unable to resolve document directory")
            return nil
        }

        let databaseUrl = docURL.appendingPathComponent("\(databaseName).\(ServiceConstants.databaseExtension)")
        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                           NSInferMappingModelAutomaticallyOption: true]
            try persistenceCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                          configurationName: nil,
                                                          at: databaseUrl, options: options)

            return CoreDataHelper(managedObjectContext: managedObjContext,
                                  persistentCoordinator: persistenceCoordinator)

        } catch {
            return nil
        }
    }
}
