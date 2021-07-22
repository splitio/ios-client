//
//  SplitDatabaseStub.swift
//  SplitTests
//
//  Created by Javier L. Avrudsky on 18/11/2020.
//  Copyright © 2020 Split. All rights reserved.
//

import Foundation
@testable import Split

class SplitDatabaseStub: SplitDatabase {

    var splitDao: SplitDao
    var mySegmentsDao: MySegmentsDao
    var eventDao: EventDao
    var impressionDao: ImpressionDao
    var impressionsCountDao: ImpressionsCountDao
    var generalInfoDao: GeneralInfoDao
    
    init(eventDao: EventDao,
         impressionDao: ImpressionDao,
         impressionsCountDao: ImpressionsCountDao,
         generalInfoDao: GeneralInfoDao,
         splitDao: SplitDao,
         mySegmentsDao: MySegmentsDao) {
        self.eventDao = eventDao
        self.impressionDao = impressionDao
        self.impressionsCountDao = impressionsCountDao
        self.splitDao = splitDao
        self.generalInfoDao = generalInfoDao
        self.mySegmentsDao = mySegmentsDao
    }
}
