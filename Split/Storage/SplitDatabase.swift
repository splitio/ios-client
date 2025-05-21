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

// Dirty but necessary for testing
protocol TestSplitDatabase {
    var coreDataHelper: CoreDataHelper { get }
}

protocol SplitDatabase {
    var splitDao: SplitDao { get }
    var mySegmentsDao: MySegmentsDao { get }
    var myLargeSegmentsDao: MySegmentsDao { get }
    var eventDao: EventDao { get }
    var impressionDao: ImpressionDao { get }
    var impressionsCountDao: ImpressionsCountDao { get }
    var hashedImpressionDao: HashedImpressionDao { get }
    var generalInfoDao: GeneralInfoDao { get }
    var attributesDao: AttributesDao { get }
    var uniqueKeyDao: UniqueKeyDao { get }
    var ruleBasedSegmentDao: RuleBasedSegmentDao { get }
}

class CoreDataSplitDatabase: SplitDatabase, TestSplitDatabase {
    var splitDao: SplitDao
    var mySegmentsDao: MySegmentsDao
    var myLargeSegmentsDao: MySegmentsDao
    var eventDao: EventDao
    var impressionDao: ImpressionDao
    var impressionsCountDao: ImpressionsCountDao
    var hashedImpressionDao: HashedImpressionDao
    var generalInfoDao: GeneralInfoDao
    var attributesDao: AttributesDao
    var uniqueKeyDao: UniqueKeyDao
    var ruleBasedSegmentDao: RuleBasedSegmentDao

    let coreDataHelper: CoreDataHelper

    // Passing a cipher allows using one from created by the Customer in the future
    init(coreDataHelper: CoreDataHelper, cipher: Cipher? = nil) {
        self.coreDataHelper = coreDataHelper
        self.splitDao = CoreDataSplitDao(coreDataHelper: coreDataHelper, cipher: cipher)
        self.eventDao = CoreDataEventDao(coreDataHelper: coreDataHelper, cipher: cipher)
        self.impressionDao = CoreDataImpressionDao(coreDataHelper: coreDataHelper, cipher: cipher)
        self.impressionsCountDao = CoreDataImpressionsCountDao(coreDataHelper: coreDataHelper, cipher: cipher)
        self.generalInfoDao = CoreDataGeneralInfoDao(coreDataHelper: coreDataHelper)
        self.mySegmentsDao = CoreDataMySegmentsDao(coreDataHelper: coreDataHelper,
                                                   entity: .mySegment,
                                                   cipher: cipher)
        self.myLargeSegmentsDao = CoreDataMySegmentsDao(coreDataHelper: coreDataHelper,
                                                        entity: .myLargeSegment,
                                                        cipher: cipher)
        self.attributesDao = CoreDataAttributesDao(coreDataHelper: coreDataHelper, cipher: cipher)
        self.uniqueKeyDao = CoreDataUniqueKeyDao(coreDataHelper: coreDataHelper, cipher: cipher)
        self.hashedImpressionDao = CoreDataHashedImpressionDao(coreDataHelper: coreDataHelper)
        self.ruleBasedSegmentDao = CoreDataRuleBasedSegmentDao(coreDataHelper: coreDataHelper, cipher: cipher)
    }
}
