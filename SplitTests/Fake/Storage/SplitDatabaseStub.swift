//
//  SplitDatabaseStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

protocol DaoProvider {
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

struct CoreDataDaoProviderMock: DaoProvider {
    var splitDao: SplitDao = SplitDaoStub()
    var mySegmentsDao: MySegmentsDao = MySegmentsDaoStub()
    var myLargeSegmentsDao: MySegmentsDao = MySegmentsDaoStub()
    var eventDao: EventDao = EventDaoStub()
    var impressionDao: ImpressionDao = ImpressionDaoStub()
    var impressionsCountDao: ImpressionsCountDao = ImpressionsCountDaoStub()
    var hashedImpressionDao: HashedImpressionDao = HashedImpressionDaoMock()
    var generalInfoDao: GeneralInfoDao = GeneralInfoDaoStub()
    var attributesDao: AttributesDao = AttributesDaoStub()
    var uniqueKeyDao: UniqueKeyDao = UniqueKeyDaoStub()
    var ruleBasedSegmentDao: RuleBasedSegmentDao = RuleBasedSegmentDaoStub()
}

class SplitDatabaseStub: SplitDatabase, TestSplitDatabase, @unchecked Sendable {

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
    
    // TestSplitDatabase conformance
    var coreDataHelper: CoreDataHelper
    
    init(daoProvider: DaoProvider, coreDataHelper: CoreDataHelper? = nil) {
        eventDao = daoProvider.eventDao
        impressionDao = daoProvider.impressionDao
        impressionsCountDao = daoProvider.impressionsCountDao
        splitDao = daoProvider.splitDao
        generalInfoDao = daoProvider.generalInfoDao
        mySegmentsDao = daoProvider.mySegmentsDao
        myLargeSegmentsDao = daoProvider.myLargeSegmentsDao
        attributesDao = daoProvider.attributesDao
        uniqueKeyDao = daoProvider.uniqueKeyDao
        hashedImpressionDao = daoProvider.hashedImpressionDao
        ruleBasedSegmentDao = daoProvider.ruleBasedSegmentDao
        self.coreDataHelper = coreDataHelper ?? CoreDataHelperStub()
    }
}
