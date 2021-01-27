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
    var splitDao: SplitDao
    var mySegmentsDao: MySegmentsDao
    var eventDao: EventDao
    var impressionDao: ImpressionDao
    var generalInfoDao: GeneralInfoDao

    private let kDataModelName = "split_cache"
    private let kDataModelExtentsion = "momd"
    private let kDatabaseExtension = "sqlite"
    private let coreDataHelper: CoreDataHelper

    init(coreDataHelper: CoreDataHelper, dispatchQueue: DispatchQueue) {
            self.coreDataHelper = coreDataHelper
            splitDao = CoreDataSplitDao(coreDataHelper: coreDataHelper, dispatchQueue: dispatchQueue)
            eventDao = CoreDataEventDao(coreDataHelper: coreDataHelper, dispatchQueue: dispatchQueue)
            impressionDao = CoreDataImpressionDao(coreDataHelper: coreDataHelper, dispatchQueue: dispatchQueue)
            generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: coreDataHelper, dispatchQueue: dispatchQueue)
            mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: coreDataHelper, dispatchQueue: dispatchQueue)
    }
}
