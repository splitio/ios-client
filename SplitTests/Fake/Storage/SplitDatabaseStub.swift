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
    var generalInfoDao: GeneralInfoDao
    
    init(eventDao: EventDao,
         impressionDao: ImpressionDao,
         generalInfoDao: GeneralInfoDao,
         splitDao: SplitDao,
         mySegmentsDao: MySegmentsDao) {
        self.eventDao = eventDao
        self.impressionDao = impressionDao
        self.splitDao = splitDao
        self.generalInfoDao = generalInfoDao
        self.mySegmentsDao = mySegmentsDao
    }
}
