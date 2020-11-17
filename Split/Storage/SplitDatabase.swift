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
    static let active: Int32 = 0
    static let deleted: Int32 = 1
}

protocol ImpressionDao {
    func insert(_ impression: Impression)
    func getBy(updatedAt: Int64, status: Int, maxRows: Int) -> [Impression]
    func update(ids: [String], newStatus: Int)
    func delete(_ impressions: [Impression])
}

protocol SplitDao {
    func insert(_ splits: [Split])
    func getAll() -> [Split]
    func update(ids: [String], newStatus: Int)
    func deleteAll()
}

protocol MySegmentsDao {
    func getBy(userKey: String) -> [String]
    func update(userKey: String, segmentList: [String])
}

// TODO: dao components will not be null
// gonna change on implementation
protocol SplitDatabase {
    var splitDao: SplitDao? { get }
    var mySegmentDao: MySegmentsDao? { get }
    var eventDao: EventDao { get }
    var impressionDao: ImpressionDao? { get }
}

class DefaultSplitDatabase: SplitDatabase {
    var splitDao: SplitDao?
    var mySegmentDao: MySegmentsDao?
    var eventDao: EventDao
    var impressionDao: ImpressionDao?

    private let kDataModelName = "SplitCache"
    private let kDataModelExtentsion = "momd"
    private let kDatabaseExtension = "sqlite"
    private let managedObjContext: NSManagedObjectContext
    private let coreDataHelper: CoreDataHelper

    init(databaseName: String, completionClosure: @escaping () -> Void) {

        guard let modelUrl = Bundle.main.url(forResource: kDataModelName, withExtension: kDataModelExtentsion) else {
            fatalError("Error loading model from bundle")
        }

        guard let modelFile = NSManagedObjectModel(contentsOf: modelUrl) else {
            fatalError("Error initializing mom from: \(modelUrl)")
        }

        let persistenceCoordinator = NSPersistentStoreCoordinator(managedObjectModel: modelFile)

        managedObjContext = NSManagedObjectContext(
            concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        managedObjContext.persistentStoreCoordinator = persistenceCoordinator

        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
            fatalError("Unable to resolve document directory")
        }
        let databaseUrl = docURL.appendingPathComponent("\(databaseName).\(self.kDatabaseExtension)")
        do {
            try persistenceCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                                          configurationName: nil,
                                                          at: databaseUrl, options: nil)

            coreDataHelper = CoreDataHelper(managedObjectContext: managedObjContext)
            eventDao = CoreDataEventDao(coreDataHelper: coreDataHelper)
            
            // TODO: Check this call
            DispatchQueue.main.sync(execute: completionClosure)
        } catch {
            fatalError("Error migrating store: \(error)")
        }


    }
}
