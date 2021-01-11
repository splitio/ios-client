//
//  SplitDatabase.swift
//  Split
//
//  Created by Javier L. Avrudsky on 06/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
import CoreData

struct StorageRecordStatus {
    static let active: Int32 = 0 // The record should be considered to be sent to the server
    static let deleted: Int32 = 1 // The record will be deleted if post succeded
}

/// Specific to CoreData
protocol CoreDataDao {
    var dbDispatchQueue: DispatchQueue { get }
    func execute(_ operation: @escaping () -> Void)
    func executeAsync(_ operation: @escaping () -> Void)
}

/// Base clase for CoreDataDao to enforce running all
/// database operation in the same serial queue to avoid threading issues
class BaseCoreDataDao {
    let coreDataHelper: CoreDataHelper
    let dbDispatchQueue: DispatchQueue
    init(coreDataHelper: CoreDataHelper, dispatchQueue: DispatchQueue) {
        self.coreDataHelper = coreDataHelper
        self.dbDispatchQueue = dispatchQueue
    }

    func execute(_ operation: @escaping () -> Void) {
        dbDispatchQueue.sync {
            operation()
        }
    }

    func executeAsync(_ operation: @escaping () -> Void) {
        dbDispatchQueue.async {
            operation()
        }
    }
}

protocol SplitDatabase {
    var splitDao: SplitDao { get }
    var mySegmentsDao: MySegmentsDao { get }
    var eventDao: EventDao { get }
    var impressionDao: ImpressionDao { get }
    var generalInfoDao: GeneralInfoDao { get }
}

class CoreDataSplitDatabase: SplitDatabase {
    private let dispatchQueue = DispatchQueue(label: "SplitCoreDataCache", target: DispatchQueue.global())
    var splitDao: SplitDao
    var mySegmentsDao: MySegmentsDao
    var eventDao: EventDao
    var impressionDao: ImpressionDao
    var generalInfoDao: GeneralInfoDao

    private let kDataModelName = "split_cache"
    private let kDataModelExtentsion = "momd"
    private let kDatabaseExtension = "sqlite"
    private let managedObjContext: NSManagedObjectContext
    private let coreDataHelper: CoreDataHelper

    init(databaseName: String, completionClosure: @escaping () -> Void) {

        let bundle = Bundle(for: type(of: self))
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

        if let context = createdManagedObjContext {
            managedObjContext = context
        } else {
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

            coreDataHelper = CoreDataHelper(managedObjectContext: managedObjContext,
                                            persistentCoordinator: persistenceCoordinator)
            splitDao = CoreDataSplitDao(coreDataHelper: coreDataHelper, dispatchQueue: dispatchQueue)
            eventDao = CoreDataEventDao(coreDataHelper: coreDataHelper, dispatchQueue: dispatchQueue)
            impressionDao = CoreDataImpressionDao(coreDataHelper: coreDataHelper, dispatchQueue: dispatchQueue)
            generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: coreDataHelper, dispatchQueue: dispatchQueue)
            mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: coreDataHelper, dispatchQueue: dispatchQueue)

            DispatchQueue.global().async(execute: completionClosure)
        } catch {
            fatalError("Error migrating store: \(error)")
        }
    }
}
