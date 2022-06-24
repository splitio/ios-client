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
    init(coreDataHelper: CoreDataHelper) {
        self.coreDataHelper = coreDataHelper
    }

    func execute(_ operation: @escaping () -> Void) {
        coreDataHelper.performAndWait {
            operation()
        }
    }

    func executeAsync(_ operation: @escaping () -> Void) {
        coreDataHelper.perform {
            operation()
        }
    }
}

protocol SplitDatabase {
    var splitDao: SplitDao { get }
    var mySegmentsDao: MySegmentsDao { get }
    var eventDao: EventDao { get }
    var impressionDao: ImpressionDao { get }
    var impressionsCountDao: ImpressionsCountDao { get }
    var generalInfoDao: GeneralInfoDao { get }
    var attributesDao: AttributesDao { get }
    var uniqueKeyDao: UniqueKeyDao { get }
}

class CoreDataSplitDatabase: SplitDatabase {
    var splitDao: SplitDao
    var mySegmentsDao: MySegmentsDao
    var eventDao: EventDao
    var impressionDao: ImpressionDao
    var impressionsCountDao: ImpressionsCountDao
    var generalInfoDao: GeneralInfoDao
    var attributesDao: AttributesDao
    var uniqueKeyDao: UniqueKeyDao

    private let coreDataHelper: CoreDataHelper

    init(coreDataHelper: CoreDataHelper) {
        self.coreDataHelper = coreDataHelper
        self.splitDao = CoreDataSplitDao(coreDataHelper: coreDataHelper)
        self.eventDao = CoreDataEventDao(coreDataHelper: coreDataHelper)
        self.impressionDao = CoreDataImpressionDao(coreDataHelper: coreDataHelper)
        self.impressionsCountDao = CoreDataImpressionsCountDao(coreDataHelper: coreDataHelper)
        self.generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: coreDataHelper)
        self.mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: coreDataHelper)
        self.attributesDao = CoreDataAttributesDao(coreDataHelper: coreDataHelper)
        self.uniqueKeyDao = CoreDataUniqueKeyDao(coreDataHelper: coreDataHelper)
    }
}
