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
    var myLargeSegmentsDao: MyLargeSegmentsDao { get }
    var eventDao: EventDao { get }
    var impressionDao: ImpressionDao { get }
    var impressionsCountDao: ImpressionsCountDao { get }
    var hashedImpressionDao: HashedImpressionDao { get }
    var generalInfoDao: GeneralInfoDao { get }
    var attributesDao: AttributesDao { get }
    var uniqueKeyDao: UniqueKeyDao { get }
}

struct CoreDataDaoProviderMock: DaoProvider {
    var splitDao: SplitDao = SplitDaoStub()
    var mySegmentsDao: MySegmentsDao = MySegmentsDaoStub()
    var myLargeSegmentsDao: MyLargeSegmentsDao = MyLargeSegmentsDaoStub()
    var eventDao: EventDao = EventDaoStub()
    var impressionDao: ImpressionDao = ImpressionDaoStub()
    var impressionsCountDao: ImpressionsCountDao = ImpressionsCountDaoStub()
    var hashedImpressionDao: HashedImpressionDao = HashedImpressionDaoMock()
    var generalInfoDao: GeneralInfoDao = GeneralInfoDaoStub()
    var attributesDao: AttributesDao = AttributesDaoStub()
    var uniqueKeyDao: UniqueKeyDao = UniqueKeyDaoStub()
}

class SplitDatabaseStub: SplitDatabase {

    var splitDao: SplitDao
    var mySegmentsDao: MySegmentsDao
    var myLargeSegmentsDao: MyLargeSegmentsDao
    var eventDao: EventDao
    var impressionDao: ImpressionDao
    var impressionsCountDao: ImpressionsCountDao
    var hashedImpressionDao: HashedImpressionDao
    var generalInfoDao: GeneralInfoDao
    var attributesDao: AttributesDao
    var uniqueKeyDao: UniqueKeyDao
    
    init(daoProvider: DaoProvider) {
        self.eventDao = daoProvider.eventDao
        self.impressionDao = daoProvider.impressionDao
        self.impressionsCountDao = daoProvider.impressionsCountDao
        self.splitDao = daoProvider.splitDao
        self.generalInfoDao = daoProvider.generalInfoDao
        self.mySegmentsDao = daoProvider.mySegmentsDao
        self.myLargeSegmentsDao = daoProvider.myLargeSegmentsDao
        self.attributesDao = daoProvider.attributesDao
        self.uniqueKeyDao = daoProvider.uniqueKeyDao
        self.hashedImpressionDao = daoProvider.hashedImpressionDao
    }
}
