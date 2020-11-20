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
    
    var splitDao: SplitDao?
    var mySegmentDao: MySegmentsDao?
    var eventDao: EventDao
    var impressionDao: ImpressionDao
    
    init(eventDao: EventDao,
         impressionDao: ImpressionDao) {
        self.eventDao = eventDao
        self.impressionDao = impressionDao
    }
}
